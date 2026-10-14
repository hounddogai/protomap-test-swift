import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped specimen tier.
    final class CappedSpecimenTierView {
        var codeText: String
        var nameText: String
        var refills: String
        var summaryText: String
        var marginText: String
        var score: String
        var quantity: String
        var allergy: String
        var discountText: String
        var notesText: String
        var unitText: String
        var statusLabel: String

        init(codeText: String, nameText: String, refills: String, summaryText: String, marginText: String, score: String, quantity: String, allergy: String, discountText: String, notesText: String, unitText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.refills = refills
            self.summaryText = summaryText
            self.marginText = marginText
            self.score = score
            self.quantity = quantity
            self.allergy = allergy
            self.discountText = discountText
            self.notesText = notesText
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedSpecimenTierView(_ item: CappedSpecimenTier) -> CappedSpecimenTierView {
        return CappedSpecimenTierView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            refills: String(item.refills),
            summaryText: Kit.Text.truncate(item.summary, limit: 120),
            marginText: String(format: "%.2f", item.margin),
            score: String(format: "%.2f", item.score),
            quantity: String(item.quantity),
            allergy: item.allergy,
            discountText: String(format: "%.2f", item.discount),
            notesText: item.notes,
            unitText: Kit.Text.truncate(item.unit, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedSpecimenTierViews(_ items: [CappedSpecimenTier]) -> [CappedSpecimenTierView] {
        var views: [CappedSpecimenTierView] = []
        for item in items {
            views.append(toCappedSpecimenTierView(item))
        }
        return views
    }

    static func sumCappedSpecimenTierView(_ view: CappedSpecimenTierView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedRefills) + parsedMargin + parsedScore
    }
}
