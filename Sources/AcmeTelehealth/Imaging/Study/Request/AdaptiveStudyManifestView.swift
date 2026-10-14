import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive study manifest.
    final class AdaptiveStudyManifestView {
        var code: String
        var labelText: String
        var currency: String
        var threshold: String
        var minimum: String
        var active: String
        var summary: String
        var startsAt: String
        var amountText: String
        var ceiling: String
        var statusLabel: String

        init(code: String, labelText: String, currency: String, threshold: String, minimum: String, active: String, summary: String, startsAt: String, amountText: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.currency = currency
            self.threshold = threshold
            self.minimum = minimum
            self.active = active
            self.summary = summary
            self.startsAt = startsAt
            self.amountText = amountText
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveStudyManifestView(_ item: AdaptiveStudyManifest) -> AdaptiveStudyManifestView {
        return AdaptiveStudyManifestView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            currency: item.currency,
            threshold: String(format: "%.2f", item.threshold),
            minimum: String(format: "%.2f", item.minimum),
            active: "\(item.active)",
            summary: item.summary,
            startsAt: String(item.startsAt),
            amountText: String(format: "%.2f", item.amount),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveStudyManifestViews(_ items: [AdaptiveStudyManifest]) -> [AdaptiveStudyManifestView] {
        var views: [AdaptiveStudyManifestView] = []
        for item in items {
            views.append(toAdaptiveStudyManifestView(item))
        }
        return views
    }

    static func sumAdaptiveStudyManifestView(_ view: AdaptiveStudyManifestView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedThreshold + parsedMinimum + Double(parsedStartsAt)
    }
}
