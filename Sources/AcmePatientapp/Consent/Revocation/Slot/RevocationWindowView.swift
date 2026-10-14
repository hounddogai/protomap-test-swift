import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation window.
    final class RevocationWindowView {
        var code: String
        var title: String
        var payer: String
        var maximum: String
        var ceiling: String
        var archived: String
        var refillsText: String
        var segmentText: String
        var country: String
        var statusLabel: String

        init(code: String, title: String, payer: String, maximum: String, ceiling: String, archived: String, refillsText: String, segmentText: String, country: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.payer = payer
            self.maximum = maximum
            self.ceiling = ceiling
            self.archived = archived
            self.refillsText = refillsText
            self.segmentText = segmentText
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationWindowView(_ item: RevocationWindow) -> RevocationWindowView {
        return RevocationWindowView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            payer: item.payer,
            maximum: String(format: "%.2f", item.maximum),
            ceiling: String(format: "%.2f", item.ceiling),
            archived: "\(item.archived)",
            refillsText: String(item.refills),
            segmentText: Kit.Text.truncate(item.segment, limit: 120),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationWindowViews(_ items: [RevocationWindow]) -> [RevocationWindowView] {
        var views: [RevocationWindowView] = []
        for item in items {
            views.append(toRevocationWindowView(item))
        }
        return views
    }

    static func sumRevocationWindowView(_ view: RevocationWindowView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedMaximum + parsedCeiling + Double(parsedRefills)
    }
}
