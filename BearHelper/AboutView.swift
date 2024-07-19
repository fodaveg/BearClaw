import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let appIcon = NSImage(named: "bear_claw_logo") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Text("App Icon not found")
                }
                VStack(alignment: .leading) {
                    Text("Bear Claw")
                        .font(.title)
                    Text("Version 0.1")
                        .font(.subheadline)
                }
            }
            .padding()
            Divider()
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.blue)
                Text("Email:")
                Link("fodaveg@fodaveg.net", destination: URL(string: "mailto:fodaveg@fodaveg.net")!)
            }
            .padding(.vertical, 5)
            HStack {
                if let mastodonIcon = NSImage(named: "mastodon") {
                    Image(nsImage: mastodonIcon)
                        .resizable()
                        .frame(width: 24, height: 24)
                } else {
                    Text("Mastodon Icon not found")
                }
                Text("Mastodon:")
                Link("@fodaveg", destination: URL(string: "https://masto.es/@fodaveg")!)
            }
            .padding(.vertical, 5)
            Spacer()
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
