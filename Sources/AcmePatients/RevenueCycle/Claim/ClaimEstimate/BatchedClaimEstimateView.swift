import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched claim estimate.
    final class BatchedClaimEstimateView {
        var code: String
        var title: String
        var payerText: String
        var copay: String
        var externalRefText: String
        var segment: String
        var category: String
        var allergyText: String
        var statusLabel: String

        init(code: String, title: String, payerText: String, copay: String, externalRefText: String, segment: String, category: String, allergyText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.payerText = payerText
            self.copay = copay
            self.externalRefText = externalRefText
            self.segment = segment
            self.category = category
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedClaimEstimateView(_ item: BatchedClaimEstimate) -> BatchedClaimEstimateView {
        return BatchedClaimEstimateView(
            code: item.code,
            title: item.title,
            payerText: item.payer,
            copay: String(format: "%.2f", item.copay),
            externalRefText: item.externalRef,
            segment: Kit.Text.truncate(item.segment, limit: 40),
            category: item.category,
            allergyText: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedClaimEstimateViews(_ items: [BatchedClaimEstimate]) -> [BatchedClaimEstimateView] {
        var views: [BatchedClaimEstimateView] = []
        for item in items {
            views.append(toBatchedClaimEstimateView(item))
        }
        return views
    }

    static func sumBatchedClaimEstimateView(_ view: BatchedClaimEstimateView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
