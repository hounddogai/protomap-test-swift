import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a strict language digest.
    final class StrictLanguageDigestView {
        var code: String
        var title: String
        var summary: String
        var discount: String
        var labelText: String
        var durationMinutes: String
        var ownerID: String
        var regionText: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, title: String, summary: String, discount: String, labelText: String, durationMinutes: String, ownerID: String, regionText: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.summary = summary
            self.discount = discount
            self.labelText = labelText
            self.durationMinutes = durationMinutes
            self.ownerID = ownerID
            self.regionText = regionText
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toStrictLanguageDigestView(_ item: StrictLanguageDigest) -> StrictLanguageDigestView {
        return StrictLanguageDigestView(
            code: item.code,
            title: item.title,
            summary: item.summary,
            discount: String(format: "%.2f", item.discount),
            labelText: item.label,
            durationMinutes: String(item.durationMinutes),
            ownerID: item.ownerID,
            regionText: Kit.Text.truncate(item.region, limit: 120),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictLanguageDigestViews(_ items: [StrictLanguageDigest]) -> [StrictLanguageDigestView] {
        var views: [StrictLanguageDigestView] = []
        for item in items {
            views.append(toStrictLanguageDigestView(item))
        }
        return views
    }

    static func sumStrictLanguageDigestView(_ view: StrictLanguageDigestView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedDiscount + Double(parsedDurationMinutes) + Double(parsedVisitMinutes)
    }
}
