import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a tiered isolation template.
    final class TieredIsolationTemplateView {
        var code: String
        var label: String
        var maximum: String
        var threshold: String
        var revisionText: String
        var statusLabel: String

        init(code: String, label: String, maximum: String, threshold: String, revisionText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.threshold = threshold
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredIsolationTemplateView(_ item: TieredIsolationTemplate) -> TieredIsolationTemplateView {
        return TieredIsolationTemplateView(
            code: item.code,
            label: item.label,
            maximum: String(format: "%.2f", item.maximum),
            threshold: String(format: "%.2f", item.threshold),
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredIsolationTemplateViews(_ items: [TieredIsolationTemplate]) -> [TieredIsolationTemplateView] {
        var views: [TieredIsolationTemplateView] = []
        for item in items {
            views.append(toTieredIsolationTemplateView(item))
        }
        return views
    }

    static func sumTieredIsolationTemplateView(_ view: TieredIsolationTemplateView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedMaximum + parsedThreshold + Double(parsedRevision)
    }
}
