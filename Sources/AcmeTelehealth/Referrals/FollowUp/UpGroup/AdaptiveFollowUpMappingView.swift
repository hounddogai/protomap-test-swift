import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a adaptive follow up mapping.
    final class AdaptiveFollowUpMappingView {
        var codeText: String
        var label: String
        var approved: String
        var capacityText: String
        var ceilingText: String
        var windowDays: String
        var refills: String
        var discountText: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, approved: String, capacityText: String, ceilingText: String, windowDays: String, refills: String, discountText: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.approved = approved
            self.capacityText = capacityText
            self.ceilingText = ceilingText
            self.windowDays = windowDays
            self.refills = refills
            self.discountText = discountText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveFollowUpMappingView(_ item: AdaptiveFollowUpMapping) -> AdaptiveFollowUpMappingView {
        return AdaptiveFollowUpMappingView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            approved: "\(item.approved)",
            capacityText: String(item.capacity),
            ceilingText: String(format: "%.2f", item.ceiling),
            windowDays: String(item.windowDays),
            refills: String(item.refills),
            discountText: String(format: "%.2f", item.discount),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveFollowUpMappingViews(_ items: [AdaptiveFollowUpMapping]) -> [AdaptiveFollowUpMappingView] {
        var views: [AdaptiveFollowUpMappingView] = []
        for item in items {
            views.append(toAdaptiveFollowUpMappingView(item))
        }
        return views
    }

    static func sumAdaptiveFollowUpMappingView(_ view: AdaptiveFollowUpMappingView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedCapacity) + parsedCeiling + Double(parsedWindowDays)
    }
}
