import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task group.
    final class TaskGroupView {
        var code: String
        var titleText: String
        var payer: String
        var clinicianIDText: String
        var graceDays: String
        var limit: String
        var statusLabel: String

        init(code: String, titleText: String, payer: String, clinicianIDText: String, graceDays: String, limit: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.payer = payer
            self.clinicianIDText = clinicianIDText
            self.graceDays = graceDays
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toTaskGroupView(_ item: TaskGroup) -> TaskGroupView {
        return TaskGroupView(
            code: item.code,
            titleText: item.title,
            payer: item.payer,
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 40),
            graceDays: String(item.graceDays),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskGroupViews(_ items: [TaskGroup]) -> [TaskGroupView] {
        var views: [TaskGroupView] = []
        for item in items {
            views.append(toTaskGroupView(item))
        }
        return views
    }

    static func sumTaskGroupView(_ view: TaskGroupView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedLimit)
    }
}
