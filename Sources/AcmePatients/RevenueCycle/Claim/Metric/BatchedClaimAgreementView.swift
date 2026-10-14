import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched claim agreement.
    final class BatchedClaimAgreementView {
        var code: String
        var label: String
        var channel: String
        var quantity: String
        var description: String
        var threshold: String
        var category: String
        var weight: String
        var ceiling: String
        var rateText: String
        var statusLabel: String

        init(code: String, label: String, channel: String, quantity: String, description: String, threshold: String, category: String, weight: String, ceiling: String, rateText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.channel = channel
            self.quantity = quantity
            self.description = description
            self.threshold = threshold
            self.category = category
            self.weight = weight
            self.ceiling = ceiling
            self.rateText = rateText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedClaimAgreementView(_ item: BatchedClaimAgreement) -> BatchedClaimAgreementView {
        return BatchedClaimAgreementView(
            code: item.code,
            label: item.label,
            channel: item.channel,
            quantity: String(item.quantity),
            description: Kit.Text.truncate(item.description, limit: 40),
            threshold: String(format: "%.2f", item.threshold),
            category: item.category,
            weight: String(format: "%.2f", item.weight),
            ceiling: String(format: "%.2f", item.ceiling),
            rateText: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedClaimAgreementViews(_ items: [BatchedClaimAgreement]) -> [BatchedClaimAgreementView] {
        var views: [BatchedClaimAgreementView] = []
        for item in items {
            views.append(toBatchedClaimAgreementView(item))
        }
        return views
    }

    static func sumBatchedClaimAgreementView(_ view: BatchedClaimAgreementView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedQuantity) + parsedThreshold + parsedWeight
    }
}
