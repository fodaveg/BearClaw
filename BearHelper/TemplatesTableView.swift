import SwiftUI
import AppKit
import BearClawCore

struct TemplatesTableView: NSViewRepresentable {
    @Binding var templates: [Template]
    var onEdit: (Template) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true

        let tableView = NSTableView()
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("TemplateColumn"))
        column.title = "Templates"
        tableView.addTableColumn(column)
        tableView.headerView = nil

        scrollView.documentView = tableView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        if let tableView = nsView.documentView as? NSTableView {
            tableView.reloadData()
        }
    }

    class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var parent: TemplatesTableView

        init(_ parent: TemplatesTableView) {
            self.parent = parent
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            return parent.templates.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let template = parent.templates[row]
            let cellIdentifier = NSUserInterfaceItemIdentifier("TemplateCell")

            if let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = template.name
                return cell
            } else {
                let cell = NSTableCellView()
                cell.identifier = cellIdentifier

                let textField = NSTextField(labelWithString: template.name)
                textField.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(textField)
                cell.textField = textField

                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
                    textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
                    textField.topAnchor.constraint(equalTo: cell.topAnchor),
                    textField.bottomAnchor.constraint(equalTo: cell.bottomAnchor)
                ])

                return cell
            }
        }

        func tableViewSelectionDidChange(_ notification: Notification) {
            if let tableView = notification.object as? NSTableView {
                let selectedRow = tableView.selectedRow
                if selectedRow >= 0 && selectedRow < parent.templates.count {
                    let selectedTemplate = parent.templates[selectedRow]
                    parent.onEdit(selectedTemplate)
                }
            }
        }
    }
}
