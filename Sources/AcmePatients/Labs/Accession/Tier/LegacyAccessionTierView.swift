import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy accession tier.
    final class LegacyAccessionTierView {
        var codeText: String
        var label: String
        var titleText: String
        var segment: String
        var visible: String
        var procedureCode: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, label: String, titleText: String, segment: String, visible: String, procedureCode: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.titleText = titleText
            self.segment = segment
            self.visible = visible
            self.procedureCode = procedureCode
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAccessionTierView(_ item: LegacyAccessionTier) -> LegacyAccessionTierView {
        return LegacyAccessionTierView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            titleText: item.title,
            segment: item.segment,
            visible: "\(item.visible)",
            procedureCode: item.procedureCode,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAccessionTierViews(_ items: [LegacyAccessionTier]) -> [LegacyAccessionTierView] {
        var views: [LegacyAccessionTierView] = []
        for item in items {
            views.append(toLegacyAccessionTierView(item))
        }
        return views
    }

    static func sumLegacyAccessionTierView(_ view: LegacyAccessionTierView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
