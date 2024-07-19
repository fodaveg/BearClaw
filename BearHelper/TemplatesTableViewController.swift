import Cocoa
import BearClawCore

class TemplatesTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    var templates: [Template] = []
    var onEdit: ((Template) -> Void)?
    var onDelete: ((Template) -> Void)?

    var tableView: NSTableView!
    var remoteViewController: CustomRemoteViewController?

    func setupRemoteView() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        remoteViewController = storyboard.instantiateController(withIdentifier: "CustomRemoteViewController") as? CustomRemoteViewController}

    override func loadView() {
        self.view = NSView()

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true

        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("TemplateColumn"))
        column.title = "Templates"
        tableView.addTableColumn(column)

        scrollView.documentView = tableView

        let addButton = NSButton(title: "+", target: self, action: #selector(addTemplate))
        addButton.translatesAutoresizingMaskIntoConstraints = false
        let removeButton = NSButton(title: "-", target: self, action: #selector(removeTemplate))
        removeButton.translatesAutoresizingMaskIntoConstraints = false

        let buttonStackView = NSStackView(views: [addButton, removeButton])
        buttonStackView.orientation = .vertical
        buttonStackView.spacing = 10
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(scrollView)
        self.view.addSubview(buttonStackView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: buttonStackView.leadingAnchor, constant: -10),
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),

            buttonStackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            buttonStackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 10)
        ])
    }

    @objc private func addTemplate() {
        let newTemplate = Template(id: UUID(), name: "New Template", content: "", tag: "")
        templates.append(newTemplate)
        tableView.reloadData()
        onEdit?(newTemplate)
    }

    @objc private func removeTemplate() {
        guard tableView.selectedRow >= 0 else { return }
        let removedTemplate = templates.remove(at: tableView.selectedRow)
        tableView.reloadData()
        onDelete?(removedTemplate)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return templates.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let template = templates[row]
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
                textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 5),
                textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -5),
                textField.topAnchor.constraint(equalTo: cell.topAnchor, constant: 5),
                textField.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -5)
            ])

            return cell
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow >= 0 else { return }
        let selectedTemplate = templates[tableView.selectedRow]
        onEdit?(selectedTemplate)
    }
}
