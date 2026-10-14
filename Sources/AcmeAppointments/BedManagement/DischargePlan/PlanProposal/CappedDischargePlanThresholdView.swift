import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a capped discharge plan threshold.
    final class CappedDischargePlanThresholdView {
        var code: String
        var title: String
        var weight: String
        var contactEmailText: String
        var windowDays: String
        var pinned: String
        var minimum: String
        var acuityText: String
        var statusLabel: String

        init(code: String, title: String, weight: String, contactEmailText: String, windowDays: String, pinned: String, minimum: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.weight = weight
            self.contactEmailText = contactEmailText
            self.windowDays = windowDays
            self.pinned = pinned
            self.minimum = minimum
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedDischargePlanThresholdView(_ item: CappedDischargePlanThreshold) -> CappedDischargePlanThresholdView {
        return CappedDischargePlanThresholdView(
            code: item.code,
            title: item.title,
            weight: String(format: "%.2f", item.weight),
            contactEmailText: item.contactEmail,
            windowDays: String(item.windowDays),
            pinned: "\(item.pinned)",
            minimum: String(format: "%.2f", item.minimum),
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedDischargePlanThresholdViews(_ items: [CappedDischargePlanThreshold]) -> [CappedDischargePlanThresholdView] {
        var views: [CappedDischargePlanThresholdView] = []
        for item in items {
            views.append(toCappedDischargePlanThresholdView(item))
        }
        return views
    }

    static func sumCappedDischargePlanThresholdView(_ view: CappedDischargePlanThresholdView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedWeight + Double(parsedWindowDays) + parsedMinimum
    }
}
