import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a primary follow up adjustment.
    final class PrimaryFollowUpAdjustmentView {
        var codeText: String
        var label: String
        var allergy: String
        var capacity: String
        var priorityText: String
        var encounterID: String
        var sequence: String
        var contactEmailText: String
        var quantity: String
        var notes: String
        var statusLabel: String

        init(codeText: String, label: String, allergy: String, capacity: String, priorityText: String, encounterID: String, sequence: String, contactEmailText: String, quantity: String, notes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.allergy = allergy
            self.capacity = capacity
            self.priorityText = priorityText
            self.encounterID = encounterID
            self.sequence = sequence
            self.contactEmailText = contactEmailText
            self.quantity = quantity
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryFollowUpAdjustmentView(_ item: PrimaryFollowUpAdjustment) -> PrimaryFollowUpAdjustmentView {
        return PrimaryFollowUpAdjustmentView(
            codeText: item.code,
            label: item.label,
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            capacity: String(item.capacity),
            priorityText: String(item.priority),
            encounterID: item.encounterID,
            sequence: String(item.sequence),
            contactEmailText: item.contactEmail,
            quantity: String(item.quantity),
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryFollowUpAdjustmentViews(_ items: [PrimaryFollowUpAdjustment]) -> [PrimaryFollowUpAdjustmentView] {
        var views: [PrimaryFollowUpAdjustmentView] = []
        for item in items {
            views.append(toPrimaryFollowUpAdjustmentView(item))
        }
        return views
    }

    static func sumPrimaryFollowUpAdjustmentView(_ view: PrimaryFollowUpAdjustmentView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedCapacity) + Double(parsedPriority) + Double(parsedSequence)
    }
}
