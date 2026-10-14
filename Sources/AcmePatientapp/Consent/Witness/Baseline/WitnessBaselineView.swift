import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness baseline.
    final class WitnessBaselineView {
        var code: String
        var label: String
        var ownerID: String
        var priorityText: String
        var contactEmailText: String
        var sequence: String
        var statusLabel: String

        init(code: String, label: String, ownerID: String, priorityText: String, contactEmailText: String, sequence: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.priorityText = priorityText
            self.contactEmailText = contactEmailText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessBaselineView(_ item: WitnessBaseline) -> WitnessBaselineView {
        return WitnessBaselineView(
            code: item.code,
            label: item.label,
            ownerID: item.ownerID,
            priorityText: String(item.priority),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 120),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessBaselineViews(_ items: [WitnessBaseline]) -> [WitnessBaselineView] {
        var views: [WitnessBaselineView] = []
        for item in items {
            views.append(toWitnessBaselineView(item))
        }
        return views
    }

    static func sumWitnessBaselineView(_ view: WitnessBaselineView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedPriority) + Double(parsedSequence)
    }
}
