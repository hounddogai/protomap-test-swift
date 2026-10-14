import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task policy.
    final class TaskPolicyView {
        var code: String
        var titleText: String
        var endsAtText: String
        var category: String
        var margin: String
        var retriesText: String
        var statusLabel: String

        init(code: String, titleText: String, endsAtText: String, category: String, margin: String, retriesText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.endsAtText = endsAtText
            self.category = category
            self.margin = margin
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toTaskPolicyView(_ item: TaskPolicy) -> TaskPolicyView {
        return TaskPolicyView(
            code: item.code,
            titleText: item.title,
            endsAtText: String(item.endsAt),
            category: Kit.Text.truncate(item.category, limit: 120),
            margin: String(format: "%.2f", item.margin),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskPolicyViews(_ items: [TaskPolicy]) -> [TaskPolicyView] {
        var views: [TaskPolicyView] = []
        for item in items {
            views.append(toTaskPolicyView(item))
        }
        return views
    }

    static func sumTaskPolicyView(_ view: TaskPolicyView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedEndsAt) + parsedMargin + Double(parsedRetries)
    }
}
