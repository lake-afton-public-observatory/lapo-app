import XCTest
@testable import LAPOApp

@MainActor
final class AppStoreTests: XCTestCase {

    private struct MockClient: LAPOClientProtocol {
        var hoursResult: Result<HoursResponse, Error>
        var whatsUpResult: Result<WhatsUpResponse, Error>

        func hours() async throws -> HoursResponse {
            try hoursResult.get()
        }

        func whatsUpNext() async throws -> WhatsUpResponse {
            try whatsUpResult.get()
        }
    }

    private enum TestError: LocalizedError {
        case boom(String)

        var errorDescription: String? {
            switch self {
            case .boom(let message): return message
            }
        }
    }

    private func makeHours() -> HoursResponse {
        HoursResponse(hours: .init(prettyHours: "7:00 PM - 11:00 PM", open: "19:00", close: "23:00"))
    }

    private func makeWhatsUp() throws -> WhatsUpResponse {
        let json = """
        {"start_time": "2026-01-01T00:00:00Z", "end_time": "2026-01-01T00:01:00Z", "objects": []}
        """.data(using: .utf8)!
        return try JSONDecoder().decode(WhatsUpResponse.self, from: json)
    }

    func testRefreshPopulatesHoursAndWhatsUpOnSuccess() async throws {
        let client = MockClient(hoursResult: .success(makeHours()), whatsUpResult: .success(try makeWhatsUp()))
        let store = AppStore(client: client)

        await store.refresh()

        XCTAssertNotNil(store.hours)
        XCTAssertNotNil(store.whatsUp)
        XCTAssertNil(store.errorMessage)
        XCTAssertFalse(store.isLoading)
    }

    func testRefreshSetsErrorMessageWhenHoursFails() async throws {
        let client = MockClient(hoursResult: .failure(TestError.boom("boom")), whatsUpResult: .success(try makeWhatsUp()))
        let store = AppStore(client: client)

        await store.refresh()

        XCTAssertNotNil(store.errorMessage)
        XCTAssertFalse(store.isLoading)
    }

    func testRefreshSetsErrorMessageWhenWhatsUpFails() async throws {
        let client = MockClient(hoursResult: .success(makeHours()), whatsUpResult: .failure(TestError.boom("boom")))
        let store = AppStore(client: client)

        await store.refresh()

        XCTAssertNotNil(store.errorMessage)
        XCTAssertFalse(store.isLoading)
    }

    func testRefreshStillPopulatesWhatsUpWhenHoursFails() async throws {
        // REGRESSION: hours and whatsUp are fetched concurrently via `async let`,
        // but were previously assigned with two sequential `try await`s inside one
        // do/catch -- if hours threw, the whatsUp result (already resolved
        // successfully in parallel) was discarded instead of being applied.
        let client = MockClient(hoursResult: .failure(TestError.boom("boom")), whatsUpResult: .success(try makeWhatsUp()))
        let store = AppStore(client: client)

        await store.refresh()

        XCTAssertNotNil(store.whatsUp)
        XCTAssertNotNil(store.errorMessage)
    }

    func testRefreshStillPopulatesHoursWhenWhatsUpFails() async throws {
        let client = MockClient(hoursResult: .success(makeHours()), whatsUpResult: .failure(TestError.boom("boom")))
        let store = AppStore(client: client)

        await store.refresh()

        XCTAssertNotNil(store.hours)
        XCTAssertNotNil(store.errorMessage)
    }

    func testRefreshClearsAStalePreviousErrorMessageOnSuccess() async throws {
        // REGRESSION-SHAPED: errorMessage is only ever set inside the catch
        // block, so if refresh() didn't explicitly reset it to nil at the
        // start, a stale error from an earlier failed refresh would linger
        // forever after a later successful retry.
        let client = MockClient(hoursResult: .success(makeHours()), whatsUpResult: .success(try makeWhatsUp()))
        let store = AppStore(client: client)
        store.errorMessage = "stale error from a previous failed refresh"

        await store.refresh()

        XCTAssertNil(store.errorMessage)
    }

    /// A one-shot gate an async call can await until another task opens it.
    /// Lets a test deterministically suspend one client call mid-flight
    /// while a second, overlapping refresh() runs to completion.
    private actor Gate {
        private var isOpen = false
        private var waiters: [CheckedContinuation<Void, Never>] = []

        func wait() async {
            if isOpen { return }
            await withCheckedContinuation { waiters.append($0) }
        }

        func open() {
            isOpen = true
            waiters.forEach { $0.resume() }
            waiters.removeAll()
        }
    }

    /// A client whose first hours() call blocks on `gate` (simulating a slow
    /// network response) while every subsequent call resolves immediately.
    private actor SlowFirstHoursClient: LAPOClientProtocol {
        private let gate: Gate
        private let whatsUpResponse: WhatsUpResponse
        private var callCount = 0

        init(gate: Gate, whatsUpResponse: WhatsUpResponse) {
            self.gate = gate
            self.whatsUpResponse = whatsUpResponse
        }

        func hours() async throws -> HoursResponse {
            callCount += 1
            if callCount == 1 {
                await gate.wait()
                return HoursResponse(hours: .init(prettyHours: "STALE", open: "0", close: "0"))
            }
            return HoursResponse(hours: .init(prettyHours: "FRESH", open: "0", close: "0"))
        }

        func whatsUpNext() async throws -> WhatsUpResponse {
            whatsUpResponse
        }
    }

    func testOverlappingRefreshDoesNotLetAStaleCallOverwriteANewerOne() async throws {
        // REGRESSION: refresh() had no guard against overlapping calls. If a
        // user pulls-to-refresh while the initial `.task` load is still in
        // flight, two refresh() calls run concurrently; whichever one's
        // network request resolves *last* used to win unconditionally, even
        // if it was the older (now-stale) call -- silently reverting state
        // the newer refresh had already applied.
        let gate = Gate()
        let client = SlowFirstHoursClient(gate: gate, whatsUpResponse: try makeWhatsUp())
        let store = AppStore(client: client)

        let firstRefresh = Task { await store.refresh() }
        try await Task.sleep(nanoseconds: 100_000_000) // let the first call reach hours() and block

        await store.refresh() // second, overlapping call resolves immediately
        XCTAssertEqual(store.hours?.hours.prettyHours, "FRESH")

        gate.open() // release the first call's stale hours() response
        await firstRefresh.value

        XCTAssertEqual(store.hours?.hours.prettyHours, "FRESH")
    }

    func testRefreshCombinesBothMessagesWhenBothRequestsFail() async throws {
        // REGRESSION: errorMessage was assigned separately in each catch block,
        // so if both hours and whatsUp failed, the second assignment silently
        // overwrote the first -- one of the two real errors was always lost.
        let client = MockClient(
            hoursResult: .failure(TestError.boom("hours failed")),
            whatsUpResult: .failure(TestError.boom("whatsUp failed"))
        )
        let store = AppStore(client: client)

        await store.refresh()

        XCTAssertNotNil(store.errorMessage)
        XCTAssertTrue(store.errorMessage?.contains("hours failed") ?? false)
        XCTAssertTrue(store.errorMessage?.contains("whatsUp failed") ?? false)
    }
}
