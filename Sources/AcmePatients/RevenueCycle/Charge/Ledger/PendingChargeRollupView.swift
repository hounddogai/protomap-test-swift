import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a pending charge rollup.
    final class PendingChargeRollupView {
        var code: String
        var label: String
        var thresholdText: String
        var reviewerText: String
        var retries: String
        var approved: String
        var statusLabel: String

        init(code: String, label: String, thresholdText: String, reviewerText: String, retries: String, approved: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.thresholdText = thresholdText
            self.reviewerText = reviewerText
            self.retries = retries
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toPendingChargeRollupView(_ item: PendingChargeRollup) -> PendingChargeRollupView {
        return PendingChargeRollupView(
            code: item.code,
            label: item.label,
            thresholdText: String(format: "%.2f", item.threshold),
            reviewerText: item.reviewer,
            retries: String(item.retries),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingChargeRollupViews(_ items: [PendingChargeRollup]) -> [PendingChargeRollupView] {
        var views: [PendingChargeRollupView] = []
        for item in items {
            views.append(toPendingChargeRollupView(item))
        }
        return views
    }

    static func sumPendingChargeRollupView(_ view: PendingChargeRollupView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedThreshold + Double(parsedRetries)
    }
}
