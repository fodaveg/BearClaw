import SwiftUI
import BearClawCore

struct TemplatesTableViewRepresentable: NSViewControllerRepresentable {
    @Binding var templates: [Template]
    var onEdit: (Template) -> Void
    var onDelete: (Template) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSViewController(context: Context) -> TemplatesTableViewController {
        let viewController = TemplatesTableViewController()
        viewController.templates = templates
        viewController.onEdit = context.coordinator.onEdit
        viewController.onDelete = context.coordinator.onDelete
        return viewController
    }

    func updateNSViewController(_ nsViewController: TemplatesTableViewController, context: Context) {
        nsViewController.templates = templates
        nsViewController.tableView.reloadData()
    }

    class Coordinator: NSObject {
        var parent: TemplatesTableViewRepresentable

        init(_ parent: TemplatesTableViewRepresentable) {
            self.parent = parent
        }

        var onEdit: (Template) -> Void {
            return parent.onEdit
        }

        var onDelete: (Template) -> Void {
            return parent.onDelete
        }
    }
}
