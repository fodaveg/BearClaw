import SwiftUI

struct AboutPopoverView: View {
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
                    
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                       let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        Text("Version \(version) (Build \(build))")
                            .font(.subheadline)
                    } else {
                        Text("Version not found")
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            Divider()
            HStack {
                if let emailIcon = NSImage(named: "email") {
                    Image(nsImage: emailIcon)
                        .resizable()
                        .frame(width: 24, height: 24)
                } else {
                    Text("Email Icon not found")
                }
                Text("Email:")
                Link("fodaveg@fodaveg.net", destination: URL(string: "mailto:fodaveg@fodaveg.net")!)
            }
            .padding(.vertical, 5)
            HStack {
                if let blueskyIcon = NSImage(named: "bluesky") {
                    Image(nsImage: blueskyIcon)
                        .resizable()
                        .frame(width: 24, height: 24)
                } else {
                    Text("Bluesky Icon not found")
                }
                Text("Bluesky:")
                Link("@fodaveg.net", destination: URL(string: "https://bsky.app/profile/fodaveg.net")!)
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
        .frame(width: 300, height: 230)
    }
}
