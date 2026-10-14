import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction audit.
    final class InteractionAuditView {
        var code: String
        var nameText: String
        var label: String
        var sequence: String
        var amount: String
        var score: String
        var statusLabel: String

        init(code: String, nameText: String, label: String, sequence: String, amount: String, score: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.label = label
            self.sequence = sequence
            self.amount = amount
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionAuditView(_ item: InteractionAudit) -> InteractionAuditView {
        return InteractionAuditView(
            code: item.code,
            nameText: item.name,
            label: item.label,
            sequence: String(item.sequence),
            amount: String(format: "%.2f", item.amount),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionAuditViews(_ items: [InteractionAudit]) -> [InteractionAuditView] {
        var views: [InteractionAuditView] = []
        for item in items {
            views.append(toInteractionAuditView(item))
        }
        return views
    }

    static func sumInteractionAuditView(_ view: InteractionAuditView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedSequence) + parsedAmount + parsedScore
    }
}
