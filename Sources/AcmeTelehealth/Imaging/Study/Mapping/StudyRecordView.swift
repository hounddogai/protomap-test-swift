import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study record.
    final class StudyRecordView {
        var code: String
        var label: String
        var durationMinutes: String
        var budget: String
        var contactEmail: String
        var updatedAt: String
        var category: String
        var statusLabel: String

        init(code: String, label: String, durationMinutes: String, budget: String, contactEmail: String, updatedAt: String, category: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.budget = budget
            self.contactEmail = contactEmail
            self.updatedAt = updatedAt
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toStudyRecordView(_ item: StudyRecord) -> StudyRecordView {
        return StudyRecordView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            durationMinutes: String(item.durationMinutes),
            budget: String(format: "%.2f", item.budget),
            contactEmail: item.contactEmail,
            updatedAt: String(item.updatedAt),
            category: Kit.Text.truncate(item.category, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyRecordViews(_ items: [StudyRecord]) -> [StudyRecordView] {
        var views: [StudyRecordView] = []
        for item in items {
            views.append(toStudyRecordView(item))
        }
        return views
    }

    static func sumStudyRecordView(_ view: StudyRecordView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedDurationMinutes) + parsedBudget + Double(parsedUpdatedAt)
    }
}
