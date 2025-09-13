import SwiftUI
import UIKit   // for UIImage in the thumbnail

struct TaskListView: View {
    @EnvironmentObject private var store: TaskStore
    @State private var search = ""
    @State private var showCompleted = true

    var filtered: [HuntTask] {
        var arr = store.tasks
        if !showCompleted { arr = arr.filter { !$0.isCompleted } }
        if !search.isEmpty {
            arr = arr.filter {
                $0.title.localizedCaseInsensitiveContains(search) ||
                $0.details.localizedCaseInsensitiveContains(search)
            }
        }
        return arr
    }

    var body: some View {
        List {
            ForEach(filtered) { task in
                NavigationLink(
                    destination: TaskDetailView(task: store.binding(for: task))
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .imageScale(.large)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.headline)
                                .strikethrough(task.isCompleted)

                            Text(task.details)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        if let data = task.imageData, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary, lineWidth: 1))
                        }
                    }
                }
            }
        }
        .navigationTitle("Scavenger Hunt")
        .searchable(text: $search)
        .safeAreaInset(edge: .bottom) {
            Toggle("Show Completed", isOn: $showCompleted)
                .padding(.horizontal)
        }
    }
}
