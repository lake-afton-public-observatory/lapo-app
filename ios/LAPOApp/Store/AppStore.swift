import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var hours: HoursResponse?
    @Published var whatsUp: WhatsUpResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client: any LAPOClientProtocol

    // Bumped on every refresh() call and captured locally so a call can tell,
    // once its network requests resolve, whether it's still the most recent
    // in-flight refresh. Without this, an overlapping refresh (e.g. the user
    // pulls-to-refresh while the initial `.task` load is still in flight)
    // can have its slower call resolve *after* the newer one and clobber
    // fresher state with stale results.
    private var refreshToken = 0

    init(client: any LAPOClientProtocol = LAPOClient.shared) {
        self.client = client
    }

    func refresh() async {
        refreshToken += 1
        let token = refreshToken

        isLoading = true
        errorMessage = nil

        async let hoursResult = client.hours()
        async let whatsUpResult = client.whatsUpNext()

        // Await and collect each result independently -- both requests run
        // concurrently, so a failure in one must not discard a result the
        // other already resolved successfully.
        var newHours: HoursResponse?
        var newWhatsUp: WhatsUpResponse?
        var errors: [String] = []
        do {
            newHours = try await hoursResult
        } catch {
            errors.append(error.localizedDescription)
        }
        do {
            newWhatsUp = try await whatsUpResult
        } catch {
            errors.append(error.localizedDescription)
        }

        // If a newer refresh() call started while this one was still
        // awaiting its network requests, drop this call's results entirely
        // -- applying them now would race with (and could overwrite) state
        // the newer call already produced.
        guard token == refreshToken else { return }

        if let newHours { hours = newHours }
        if let newWhatsUp { whatsUp = newWhatsUp }
        // If both requests fail, combine both messages -- assigning
        // errorMessage separately in each catch would silently drop
        // whichever one was set first.
        errorMessage = errors.isEmpty ? nil : errors.joined(separator: "\n")

        isLoading = false
    }
}
