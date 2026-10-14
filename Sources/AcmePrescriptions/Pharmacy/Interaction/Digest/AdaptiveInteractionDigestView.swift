import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive interaction digest.
    final class AdaptiveInteractionDigestView {
        var code: String
        var label: String
        var windowDaysText: String
        var limitText: String
        var floorValue: String
        var discountText: String
        var startsAt: String
        var allergy: String
        var locale: String
        var statusLabel: String

        init(code: String, label: String, windowDaysText: String, limitText: String, floorValue: String, discountText: String, startsAt: String, allergy: String, locale: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.windowDaysText = windowDaysText
            self.limitText = limitText
            self.floorValue = floorValue
            self.discountText = discountText
            self.startsAt = startsAt
            self.allergy = allergy
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveInteractionDigestView(_ item: AdaptiveInteractionDigest) -> AdaptiveInteractionDigestView {
        return AdaptiveInteractionDigestView(
            code: item.code,
            label: item.label,
            windowDaysText: String(item.windowDays),
            limitText: String(item.limit),
            floorValue: String(format: "%.2f", item.floorValue),
            discountText: String(format: "%.2f", item.discount),
            startsAt: String(item.startsAt),
            allergy: item.allergy,
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveInteractionDigestViews(_ items: [AdaptiveInteractionDigest]) -> [AdaptiveInteractionDigestView] {
        var views: [AdaptiveInteractionDigestView] = []
        for item in items {
            views.append(toAdaptiveInteractionDigestView(item))
        }
        return views
    }

    static func sumAdaptiveInteractionDigestView(_ view: AdaptiveInteractionDigestView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedLimit) + parsedFloorValue
    }
}
