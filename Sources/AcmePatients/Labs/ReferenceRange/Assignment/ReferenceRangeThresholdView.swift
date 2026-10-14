import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range threshold.
    final class ReferenceRangeThresholdView {
        var code: String
        var name: String
        var threshold: String
        var refillsText: String
        var externalRef: String
        var payer: String
        var windowDays: String
        var locale: String
        var statusLabel: String

        init(code: String, name: String, threshold: String, refillsText: String, externalRef: String, payer: String, windowDays: String, locale: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.refillsText = refillsText
            self.externalRef = externalRef
            self.payer = payer
            self.windowDays = windowDays
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeThresholdView(_ item: ReferenceRangeThreshold) -> ReferenceRangeThresholdView {
        return ReferenceRangeThresholdView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            threshold: String(format: "%.2f", item.threshold),
            refillsText: String(item.refills),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            payer: item.payer,
            windowDays: String(item.windowDays),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeThresholdViews(_ items: [ReferenceRangeThreshold]) -> [ReferenceRangeThresholdView] {
        var views: [ReferenceRangeThresholdView] = []
        for item in items {
            views.append(toReferenceRangeThresholdView(item))
        }
        return views
    }

    static func sumReferenceRangeThresholdView(_ view: ReferenceRangeThresholdView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedThreshold + Double(parsedRefills) + Double(parsedWindowDays)
    }
}
