import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up bundle.
    final class FollowUpBundleView {
        var code: String
        var label: String
        var capacityText: String
        var threshold: String
        var weight: String
        var contactEmail: String
        var visitMinutesText: String
        var statusLabel: String

        init(code: String, label: String, capacityText: String, threshold: String, weight: String, contactEmail: String, visitMinutesText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacityText = capacityText
            self.threshold = threshold
            self.weight = weight
            self.contactEmail = contactEmail
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpBundleView(_ item: FollowUpBundle) -> FollowUpBundleView {
        return FollowUpBundleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 80),
            capacityText: String(item.capacity),
            threshold: String(format: "%.2f", item.threshold),
            weight: String(format: "%.2f", item.weight),
            contactEmail: item.contactEmail,
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpBundleViews(_ items: [FollowUpBundle]) -> [FollowUpBundleView] {
        var views: [FollowUpBundleView] = []
        for item in items {
            views.append(toFollowUpBundleView(item))
        }
        return views
    }

    static func sumFollowUpBundleView(_ view: FollowUpBundleView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedCapacity) + parsedThreshold + parsedWeight
    }
}
