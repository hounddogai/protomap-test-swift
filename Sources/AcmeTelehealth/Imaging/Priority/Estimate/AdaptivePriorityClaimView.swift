import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive priority claim.
    final class AdaptivePriorityClaimView {
        var code: String
        var label: String
        var diagnosisCode: String
        var updatedAt: String
        var threshold: String
        var title: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCode: String, updatedAt: String, threshold: String, title: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.updatedAt = updatedAt
            self.threshold = threshold
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptivePriorityClaimView(_ item: AdaptivePriorityClaim) -> AdaptivePriorityClaimView {
        return AdaptivePriorityClaimView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            diagnosisCode: item.diagnosisCode,
            updatedAt: String(item.updatedAt),
            threshold: String(format: "%.2f", item.threshold),
            title: Kit.Text.truncate(item.title, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptivePriorityClaimViews(_ items: [AdaptivePriorityClaim]) -> [AdaptivePriorityClaimView] {
        var views: [AdaptivePriorityClaimView] = []
        for item in items {
            views.append(toAdaptivePriorityClaimView(item))
        }
        return views
    }

    static func sumAdaptivePriorityClaimView(_ view: AdaptivePriorityClaimView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedUpdatedAt) + parsedThreshold
    }
}
