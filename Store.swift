import SwiftUI
import Foundation

@MainActor
final class TaskStore: ObservableObject {
    @Published var tasks: [HuntTask] = [
        HuntTask(title: "Blue bench", details: "Find a blue bench on campus and attach a photo."),
        HuntTask(title: "Campus statue", details: "Snap the main statue and attach it."),
        HuntTask(title: "Library entrance", details: "Attach a photo of the library doors."),
        HuntTask(title: "Coffee spot", details: "Grab a pic of your favorite café corner.")
    ]

    func binding(for task: HuntTask) -> Binding<HuntTask> {
        guard let idx = tasks.firstIndex(of: task) else {
            return .constant(task)
        }
        return Binding(
            get: { self.tasks[idx] },
            set: { self.tasks[idx] = $0 }
        )
    }
}
