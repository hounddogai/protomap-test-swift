import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict census digest.
    final class StrictCensusDigestView {
        var code: String
        var titleText: String
        var ownerID: String
        var reviewer: String
        var description: String
        var quantityText: String
        var statusLabel: String

        init(code: String, titleText: String, ownerID: String, reviewer: String, description: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ownerID = ownerID
            self.reviewer = reviewer
            self.description = description
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictCensusDigestView(_ item: StrictCensusDigest) -> StrictCensusDigestView {
        return StrictCensusDigestView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: Kit.Text.truncate(item.title, limit: 64),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            reviewer: item.reviewer,
            description: Kit.Text.truncate(item.description, limit: 120),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictCensusDigestViews(_ items: [StrictCensusDigest]) -> [StrictCensusDigestView] {
        var views: [StrictCensusDigestView] = []
        for item in items {
            views.append(toStrictCensusDigestView(item))
        }
        return views
    }

    static func sumStrictCensusDigestView(_ view: StrictCensusDigestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
