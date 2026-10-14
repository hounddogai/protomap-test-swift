import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a fallback denial baseline.
    final class FallbackDenialBaselineView {
        var codeText: String
        var name: String
        var patientRef: String
        var minimum: String
        var externalRef: String
        var source: String
        var discount: String
        var margin: String
        var active: String
        var statusLabel: String

        init(codeText: String, name: String, patientRef: String, minimum: String, externalRef: String, source: String, discount: String, margin: String, active: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.patientRef = patientRef
            self.minimum = minimum
            self.externalRef = externalRef
            self.source = source
            self.discount = discount
            self.margin = margin
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackDenialBaselineView(_ item: FallbackDenialBaseline) -> FallbackDenialBaselineView {
        return FallbackDenialBaselineView(
            codeText: item.code,
            name: item.name,
            patientRef: item.patientRef,
            minimum: String(format: "%.2f", item.minimum),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            source: item.source,
            discount: String(format: "%.2f", item.discount),
            margin: String(format: "%.2f", item.margin),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackDenialBaselineViews(_ items: [FallbackDenialBaseline]) -> [FallbackDenialBaselineView] {
        var views: [FallbackDenialBaselineView] = []
        for item in items {
            views.append(toFallbackDenialBaselineView(item))
        }
        return views
    }

    static func sumFallbackDenialBaselineView(_ view: FallbackDenialBaselineView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMinimum + parsedDiscount + parsedMargin
    }
}
