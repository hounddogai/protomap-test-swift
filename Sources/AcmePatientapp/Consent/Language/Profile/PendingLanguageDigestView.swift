import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a pending language digest.
    final class PendingLanguageDigestView {
        var codeText: String
        var nameText: String
        var payerText: String
        var bed: String
        var graceDaysText: String
        var cost: String
        var ceiling: String
        var reviewer: String
        var priority: String
        var statusLabel: String

        init(codeText: String, nameText: String, payerText: String, bed: String, graceDaysText: String, cost: String, ceiling: String, reviewer: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.payerText = payerText
            self.bed = bed
            self.graceDaysText = graceDaysText
            self.cost = cost
            self.ceiling = ceiling
            self.reviewer = reviewer
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toPendingLanguageDigestView(_ item: PendingLanguageDigest) -> PendingLanguageDigestView {
        return PendingLanguageDigestView(
            codeText: item.code,
            nameText: item.name,
            payerText: item.payer,
            bed: item.bed,
            graceDaysText: String(item.graceDays),
            cost: String(format: "%.2f", item.cost),
            ceiling: String(format: "%.2f", item.ceiling),
            reviewer: item.reviewer,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingLanguageDigestViews(_ items: [PendingLanguageDigest]) -> [PendingLanguageDigestView] {
        var views: [PendingLanguageDigestView] = []
        for item in items {
            views.append(toPendingLanguageDigestView(item))
        }
        return views
    }

    static func sumPendingLanguageDigestView(_ view: PendingLanguageDigestView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedGraceDays) + parsedCost + parsedCeiling
    }
}
