import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending modality policy.
    final class PendingModalityPolicyView {
        var code: String
        var title: String
        var minimumText: String
        var costText: String
        var timezone: String
        var attempts: String
        var ratio: String
        var thresholdText: String
        var statusLabel: String

        init(code: String, title: String, minimumText: String, costText: String, timezone: String, attempts: String, ratio: String, thresholdText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.minimumText = minimumText
            self.costText = costText
            self.timezone = timezone
            self.attempts = attempts
            self.ratio = ratio
            self.thresholdText = thresholdText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingModalityPolicyView(_ item: PendingModalityPolicy) -> PendingModalityPolicyView {
        return PendingModalityPolicyView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            minimumText: String(format: "%.2f", item.minimum),
            costText: String(format: "%.2f", item.cost),
            timezone: item.timezone,
            attempts: String(item.attempts),
            ratio: String(format: "%.2f", item.ratio),
            thresholdText: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingModalityPolicyViews(_ items: [PendingModalityPolicy]) -> [PendingModalityPolicyView] {
        var views: [PendingModalityPolicyView] = []
        for item in items {
            views.append(toPendingModalityPolicyView(item))
        }
        return views
    }

    static func sumPendingModalityPolicyView(_ view: PendingModalityPolicyView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedMinimum + parsedCost + Double(parsedAttempts)
    }
}
