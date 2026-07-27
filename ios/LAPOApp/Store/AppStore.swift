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
        do {
            async let hoursResult = client.hours()
            async let whatsUpResult = client.whatsUpNext()
            hours = try await hoursResult
            whatsUp = try await whatsUpResult
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
