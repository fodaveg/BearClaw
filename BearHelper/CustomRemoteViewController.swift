import Cocoa

class CustomRemoteViewController: NSViewController {

    func handleServiceTermination(with error: Error) {
        print("Remote view service terminated with error: \(error.localizedDescription)")
    }
}
