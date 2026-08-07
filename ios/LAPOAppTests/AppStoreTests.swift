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

    private enum TestError: Error {
        case boom
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
        let client = MockClient(hoursResult: .failure(TestError.boom), whatsUpResult: .success(try makeWhatsUp()))
        let store = AppStore(client: client)

        await store.refresh()

        XCTAssertNotNil(store.errorMessage)
        XCTAssertFalse(store.isLoading)
    }

    func testRefreshSetsErrorMessageWhenWhatsUpFails() async throws {
        let client = MockClient(hoursResult: .success(makeHours()), whatsUpResult: .failure(TestError.boom))
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
        let client = MockClient(hoursResult: .failure(TestError.boom), whatsUpResult: .success(try makeWhatsUp()))
        let store = AppStore(client: client)

        await store.refresh()

        XCTAssertNotNil(store.whatsUp)
        XCTAssertNotNil(store.errorMessage)
    }

    func testRefreshStillPopulatesHoursWhenWhatsUpFails() async throws {
        let client = MockClient(hoursResult: .success(makeHours()), whatsUpResult: .failure(TestError.boom))
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
}
