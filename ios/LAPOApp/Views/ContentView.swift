import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                    if store.isLoading && store.hours == nil {
                        loadingView
                    } else {
                        VStack(spacing: 16) {
                            HoursCard()
                            WhatsUpList()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .refreshable { await store.refresh() }
        }
        .task { await store.refresh() }
        .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
            Button("Retry") { Task { await store.refresh() } }
            Button("OK", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Lake Afton")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Public Observatory")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private var loadingView: some View {
        ProgressView()
            .tint(.white)
            .scaleEffect(1.2)
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStore())
}
