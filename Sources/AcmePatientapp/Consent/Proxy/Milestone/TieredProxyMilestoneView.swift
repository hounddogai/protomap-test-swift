import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a tiered proxy milestone.
    final class TieredProxyMilestoneView {
        var code: String
        var name: String
        var amount: String
        var ownerIDText: String
        var attempts: String
        var batchSizeText: String
        var threshold: String
        var visitMinutes: String
        var ceiling: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, name: String, amount: String, ownerIDText: String, attempts: String, batchSizeText: String, threshold: String, visitMinutes: String, ceiling: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.amount = amount
            self.ownerIDText = ownerIDText
            self.attempts = attempts
            self.batchSizeText = batchSizeText
            self.threshold = threshold
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toTieredProxyMilestoneView(_ item: TieredProxyMilestone) -> TieredProxyMilestoneView {
        return TieredProxyMilestoneView(
            code: item.code,
            name: item.name,
            amount: String(format: "%.2f", item.amount),
            ownerIDText: item.ownerID,
            attempts: String(item.attempts),
            batchSizeText: String(item.batchSize),
            threshold: String(format: "%.2f", item.threshold),
            visitMinutes: String(item.visitMinutes),
            ceiling: String(format: "%.2f", item.ceiling),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredProxyMilestoneViews(_ items: [TieredProxyMilestone]) -> [TieredProxyMilestoneView] {
        var views: [TieredProxyMilestoneView] = []
        for item in items {
            views.append(toTieredProxyMilestoneView(item))
        }
        return views
    }

    static func sumTieredProxyMilestoneView(_ view: TieredProxyMilestoneView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedAmount + Double(parsedAttempts) + Double(parsedBatchSize)
    }
}
