import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding entry.
    final class RoundingEntryView {
        var codeText: String
        var labelText: String
        var approved: String
        var acuity: String
        var sequence: String
        var amount: String
        var segmentText: String
        var name: String
        var statusLabel: String

        init(codeText: String, labelText: String, approved: String, acuity: String, sequence: String, amount: String, segmentText: String, name: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.approved = approved
            self.acuity = acuity
            self.sequence = sequence
            self.amount = amount
            self.segmentText = segmentText
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingEntryView(_ item: RoundingEntry) -> RoundingEntryView {
        return RoundingEntryView(
            codeText: item.code,
            labelText: item.label,
            approved: "\(item.approved)",
            acuity: String(item.acuity),
            sequence: String(item.sequence),
            amount: String(format: "%.2f", item.amount),
            segmentText: item.segment,
            name: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingEntryViews(_ items: [RoundingEntry]) -> [RoundingEntryView] {
        var views: [RoundingEntryView] = []
        for item in items {
            views.append(toRoundingEntryView(item))
        }
        return views
    }

    static func sumRoundingEntryView(_ view: RoundingEntryView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedAcuity) + Double(parsedSequence) + parsedAmount
    }
}
