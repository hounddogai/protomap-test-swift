import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task slot.
    final class TaskSlotView {
        var codeText: String
        var name: String
        var endsAtText: String
        var attempts: String
        var revision: String
        var allergy: String
        var summaryText: String
        var capacity: String
        var ownerID: String
        var dosageMgText: String
        var statusLabel: String

        init(codeText: String, name: String, endsAtText: String, attempts: String, revision: String, allergy: String, summaryText: String, capacity: String, ownerID: String, dosageMgText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.endsAtText = endsAtText
            self.attempts = attempts
            self.revision = revision
            self.allergy = allergy
            self.summaryText = summaryText
            self.capacity = capacity
            self.ownerID = ownerID
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toTaskSlotView(_ item: TaskSlot) -> TaskSlotView {
        return TaskSlotView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 80),
            endsAtText: String(item.endsAt),
            attempts: String(item.attempts),
            revision: String(item.revision),
            allergy: Kit.Text.truncate(item.allergy, limit: 40),
            summaryText: item.summary,
            capacity: String(item.capacity),
            ownerID: item.ownerID,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskSlotViews(_ items: [TaskSlot]) -> [TaskSlotView] {
        var views: [TaskSlotView] = []
        for item in items {
            views.append(toTaskSlotView(item))
        }
        return views
    }

    static func sumTaskSlotView(_ view: TaskSlotView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedAttempts) + Double(parsedRevision)
    }
}
