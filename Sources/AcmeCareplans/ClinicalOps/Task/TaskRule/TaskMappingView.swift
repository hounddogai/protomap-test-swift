import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task mapping.
    final class TaskMappingView {
        var code: String
        var title: String
        var visitMinutesText: String
        var score: String
        var locale: String
        var refills: String
        var priorityText: String
        var notes: String
        var statusLabel: String

        init(code: String, title: String, visitMinutesText: String, score: String, locale: String, refills: String, priorityText: String, notes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutesText = visitMinutesText
            self.score = score
            self.locale = locale
            self.refills = refills
            self.priorityText = priorityText
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toTaskMappingView(_ item: TaskMapping) -> TaskMappingView {
        return TaskMappingView(
            code: item.code,
            title: item.title,
            visitMinutesText: String(item.visitMinutes),
            score: String(format: "%.2f", item.score),
            locale: item.locale,
            refills: String(item.refills),
            priorityText: String(item.priority),
            notes: Kit.Text.truncate(item.notes, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskMappingViews(_ items: [TaskMapping]) -> [TaskMappingView] {
        var views: [TaskMappingView] = []
        for item in items {
            views.append(toTaskMappingView(item))
        }
        return views
    }

    static func sumTaskMappingView(_ view: TaskMappingView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedVisitMinutes) + parsedScore + Double(parsedRefills)
    }
}
