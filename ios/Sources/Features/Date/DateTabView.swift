import SwiftUI

struct DateTabView: View {
    @AppStorage("gm_lang") private var language = "id"

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                language == "en" ? "Date planner is coming next" : "Date planner akan dipindahkan berikutnya",
                systemImage: "heart.text.square",
                description: Text(language == "en"
                    ? "The wishlist and shared-spending tools from the web app are planned for a later native migration step."
                    : "Fitur wishlist dan catatan pengeluaran berdua dari aplikasi web akan dipindahkan pada tahap native berikutnya.")
            )
            .navigationTitle("Date")
        }
    }
}
