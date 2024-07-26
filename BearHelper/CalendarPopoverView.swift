import SwiftUI

struct CalendarPopoverView: View {
    var onSelectDate: (Date) -> Void
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Select Date")
                .font(.headline)
                .padding(.top)
                .padding(.horizontal)
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
            Button(action: {
                onSelectDate(selectedDate)
            }) {
                Text("Create Note")
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .frame(width: 300, height: 300)
    }
}
