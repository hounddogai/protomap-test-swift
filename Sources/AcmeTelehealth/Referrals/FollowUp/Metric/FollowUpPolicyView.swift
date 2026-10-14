import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up policy.
    final class FollowUpPolicyView {
        var codeText: String
        var label: String
        var rateText: String
        var phone: String
        var threshold: String
        var updatedAt: String
        var revision: String
        var capacity: String
        var statusLabel: String

        init(codeText: String, label: String, rateText: String, phone: String, threshold: String, updatedAt: String, revision: String, capacity: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.rateText = rateText
            self.phone = phone
            self.threshold = threshold
            self.updatedAt = updatedAt
            self.revision = revision
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpPolicyView(_ item: FollowUpPolicy) -> FollowUpPolicyView {
        return FollowUpPolicyView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 120),
            rateText: String(format: "%.2f", item.rate),
            phone: item.phone,
            threshold: String(format: "%.2f", item.threshold),
            updatedAt: String(item.updatedAt),
            revision: String(item.revision),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpPolicyViews(_ items: [FollowUpPolicy]) -> [FollowUpPolicyView] {
        var views: [FollowUpPolicyView] = []
        for item in items {
            views.append(toFollowUpPolicyView(item))
        }
        return views
    }

    static func sumFollowUpPolicyView(_ view: FollowUpPolicyView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedRate + parsedThreshold + Double(parsedUpdatedAt)
    }
}
