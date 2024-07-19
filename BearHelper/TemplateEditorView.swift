import SwiftUI
import Carbon.HIToolbox.Events
import BearClawCore

struct TemplateEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var template: Template
    @State private var newName: String
    @State private var newContent: String
    @State private var newTag: String
    @State private var newIsDaily: Bool
    @FocusState private var focusedField: Field?
    var onSave: (Template) -> Void

    enum Field: Hashable {
        case name
        case content
        case tag
    }

    init(template: Binding<Template>, onSave: @escaping (Template) -> Void) {
        self._template = template
        self.onSave = onSave
        self._newName = State(initialValue: template.wrappedValue.name)
        self._newContent = State(initialValue: template.wrappedValue.content)
        self._newTag = State(initialValue: template.wrappedValue.tag)
        self._newIsDaily = State(initialValue: template.wrappedValue.isDaily)
    }

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Template Name")) {
                    TextField("Name", text: $newName)
                        .focused($focusedField, equals: .name)
                        .onSubmit {
                            focusedField = .content
                        }
                }
                Section(header: Text("Content")) {
                    VStack(spacing: 0) {
                        HStack {
                            Button("Date") {
                                insertSnippet("%date()%")
                            }
                            Spacer()
                            Button("Daily") {
                                insertSnippet("\(SettingsManager.shared.dailySectionHeader)")
                            }
                            Spacer()
                            Button("Calendar") {
                                insertSnippet("\(SettingsManager.shared.calendarSectionHeader)")
                            }
                            Spacer()
                            Button("Sync Now") {
                                insertSnippet("%syncnow()%")
                            }
                            Spacer()
                            Button("Yesterday") {
                                insertSnippet("[%date(-1)%](fodabear://open-daily-note-for-date?date=%date(-1)%)")
                            }
                            Spacer()
                            Button("Tomorrow") {
                                insertSnippet("[%date(+1)%](fodabear://open-daily-note-for-date?date=%date(+1)%)")
                            }
                            Spacer()
                            Button("Tag") {
                                insertSnippet("%tag_placeholder%")
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.2))

                        TextEditorWithTabSupport(text: $newContent, focusedField: $focusedField)
                            .focused($focusedField, equals: .content)
                            .frame(minHeight: 200)
                    }
                }
                Section(header: Text("Tag")) {
                    TextField("Tag", text: $newTag)
                        .focused($focusedField, equals: .tag)
                        .onSubmit {
                            focusedField = nil
                        }
                }
                Section(header: Text("Daily")) {
                    Toggle("Is Daily", isOn: $newIsDaily)
                }
            }
            .padding()

            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Button("Save") {
                    var updatedTemplate = template
                    updatedTemplate.name = newName
                    updatedTemplate.content = newContent
                    updatedTemplate.tag = newTag
                    updatedTemplate.isDaily = newIsDaily
                    onSave(updatedTemplate)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
        .background(WindowAccessor { window in
            window?.styleMask.insert([.resizable])
        })
        .onAppear {
            focusedField = .name
        }
    }

    func insertSnippet(_ snippet: String) {
        if let selectedRange = NSApp.keyWindow?.firstResponder as? NSTextView {
            selectedRange.insertText(snippet, replacementRange: selectedRange.selectedRange())
        }
    }
}

struct TextEditorWithTabSupport: NSViewRepresentable {
    @Binding var text: String
    @FocusState.Binding var focusedField: TemplateEditorView.Field?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextViewWrapper()
        scrollView.textView.delegate = context.coordinator
        scrollView.textView.string = text
        scrollView.textView.isEditable = true
        scrollView.textView.isRichText = false
        scrollView.textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let scrollView = nsView as? NSTextViewWrapper {
            if scrollView.textView.string != text {
                scrollView.textView.string = text
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextEditorWithTabSupport

        init(_ parent: TextEditorWithTabSupport) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                parent.text = textView.string
            }
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                parent.focusedField = .tag
                return true
            }
            return false
        }
    }
}

class NSTextViewWrapper: NSScrollView {
    let textView = NSTextView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.documentView = textView
        self.hasVerticalScroller = true
        self.autohidesScrollers = true
        self.borderType = .bezelBorder

        textView.minSize = NSSize(width: 0.0, height: 0.0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct WindowAccessor: View {
    var callback: (NSWindow?) -> Void

    var body: some View {
        GeometryReader { _ in
            Color.clear
                .preference(key: WindowPreferenceKey.self, value: NSApp.keyWindow)
        }
        .onPreferenceChange(WindowPreferenceKey.self, perform: callback)
    }
}

struct WindowPreferenceKey: PreferenceKey {
    typealias Value = NSWindow?

    static var defaultValue: NSWindow?

    static func reduce(value: inout NSWindow?, nextValue: () -> NSWindow?) {
        value = value ?? nextValue()
    }
}
