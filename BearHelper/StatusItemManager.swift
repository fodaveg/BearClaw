import Cocoa
import SwiftUI
import BearClawCore

@MainActor
class StatusItemManager: NSObject, NSMenuItemValidation {
    static let shared = StatusItemManager()
    var statusItem: NSStatusItem!
    var popover: NSPopover?
    var aboutPopover: NSPopover?
    private var aboutPopoverTransiencyMonitor: Any?
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name(isDarkMode() ? "bear_paw_icon_dark" : "bear_paw_icon_light"))
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func handleClick() {
        print("Status bar item clicked")
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            executeDefaultAction()
        }
    }
    
    @objc private func executeDefaultAction() {
        let defaultAction = SettingsManager.shared.defaultAction
        print("Executing default action: \(defaultAction)")
        switch defaultAction {
        case "home":
            NoteHandler.shared.openHomeNote()
        case "daily":
            NoteHandler.shared.openDailyNote()
        default:
            print("Left click action is disabled")
        }
    }
    
    @objc func showMenu() {
        print("Showing menu")
        let menu = NSMenu()
        addMenuItem(to: menu, title: "Open Home Note", action: #selector(NoteHandler.shared.openHomeNote), target: NoteHandler.shared)
        menu.addItem(NSMenuItem.separator())
        addMenuItem(to: menu, title: "Open Daily Note", action: #selector(NoteHandler.shared.openDailyNote), target: NoteHandler.shared)
        addMenuItem(to: menu, title: "Create Custom Daily Note", action: #selector(showDatePicker), target: self)
        menu.addItem(NSMenuItem.separator())
        addCustomTemplateItems(to: menu)
        menu.addItem(NSMenuItem.separator())
        addMenuItem(to: menu, title: "Sync Calendar Events", action: #selector(CalendarSyncManager.shared.syncNow), target: CalendarSyncManager.shared)
        menu.addItem(NSMenuItem.separator())
        addMenuItem(to: menu, title: "Settings", action: #selector(AppDelegate.shared.openSettings), target: AppDelegate.shared)
        addMenuItem(to: menu, title: "About", action: #selector(openAbout), target: self)
        menu.addItem(NSMenuItem.separator())
        addMenuItem(to: menu, title: "Quit", action: #selector(NSApplication.terminate(_:)), target: nil)
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.statusItem.menu = nil
            self?.restoreLeftClickAction()
            
        }
    }
    
    private func addMenuItem(to menu: NSMenu, title: String, action: Selector, target: AnyObject?) {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        menuItem.target = target
        menu.addItem(menuItem)
    }
    
    private func addCustomTemplateItems(to menu: NSMenu) {
        let templates = SettingsManager.shared.loadTemplates()
        for template in templates where !template.isDaily {
            addMenuItem(to: menu, title: "Create \(template.name) Note", action: #selector(NoteHandler.shared.openTemplateNote(_:)), target: NoteHandler.shared)
        }
    }
    
    @objc func showDatePicker() {
        if popover == nil {
            popover = NSPopover()
            popover?.contentViewController = NSHostingController(rootView: CalendarPopoverView(onSelectDate: { (selectedDate: Date) in
                self.popover?.performClose(nil)
                let selectedDateString = DateUtils.getCurrentDateFormatted(date: selectedDate)
                NoteHandler.shared.createDailyNoteWithDateString(selectedDateString)
            }))
            popover?.behavior = .transient
        }
        
        if let button = statusItem.button {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        }
    }
    
    func restoreLeftClickAction() {
        if let button = statusItem.button {
            print("Restoring left click action")
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func openAbout() {
        print("Opening About window")
        let aboutView = AboutPopoverView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.contentView = NSHostingView(rootView: aboutView)
        window.title = "About"
        let aboutWindowController = NSWindowController(window: window)
        aboutWindowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    private func isDarkMode() -> Bool {
        let appearance = NSApp.effectiveAppearance
        return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        print("Validating menu item: \(menuItem.title)")
        
        return true
    }
    
}
