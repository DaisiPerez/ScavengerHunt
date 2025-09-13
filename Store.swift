import SwiftUI
import Foundation

@MainActor
final class TaskStore: ObservableObject {
    @Published var tasks: [HuntTask] = [
        HuntTask(title: "Waterfall", details: "Find a waterfall and attach a photo of it."),
        HuntTask(title: "Yellow Leaf", details: "Spot a yellow leaf and attach a photo of it."),
        HuntTask(title: "Pink Flowers", details: "Attach a photo of pink flowers caught in the wild."),
        HuntTask(title: "Yellow Flower", details: "Attach a photo of a yellow flower caught in the wild.")
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
