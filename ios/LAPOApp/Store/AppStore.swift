import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var hours: HoursResponse?
    @Published var whatsUp: WhatsUpResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client: any LAPOClientProtocol

    init(client: any LAPOClientProtocol = LAPOClient.shared) {
        self.client = client
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        async let hoursResult = client.hours()
        async let whatsUpResult = client.whatsUpNext()

        // Await and assign each result independently -- both requests run
        // concurrently, so a failure in one must not discard a result the
        // other already resolved successfully.
        do {
            hours = try await hoursResult
        } catch {
            errorMessage = error.localizedDescription
        }
        do {
            whatsUp = try await whatsUpResult
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
