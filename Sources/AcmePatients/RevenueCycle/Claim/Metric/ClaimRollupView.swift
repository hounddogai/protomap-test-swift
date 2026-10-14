import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim rollup.
    final class ClaimRollupView {
        var code: String
        var name: String
        var ceilingText: String
        var segment: String
        var patientRefText: String
        var discount: String
        var encounterID: String
        var updatedAtText: String
        var payer: String
        var statusLabel: String

        init(code: String, name: String, ceilingText: String, segment: String, patientRefText: String, discount: String, encounterID: String, updatedAtText: String, payer: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ceilingText = ceilingText
            self.segment = segment
            self.patientRefText = patientRefText
            self.discount = discount
            self.encounterID = encounterID
            self.updatedAtText = updatedAtText
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toClaimRollupView(_ item: ClaimRollup) -> ClaimRollupView {
        return ClaimRollupView(
            code: item.code,
            name: item.name,
            ceilingText: String(format: "%.2f", item.ceiling),
            segment: Kit.Text.truncate(item.segment, limit: 64),
            patientRefText: item.patientRef,
            discount: String(format: "%.2f", item.discount),
            encounterID: item.encounterID,
            updatedAtText: String(item.updatedAt),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimRollupViews(_ items: [ClaimRollup]) -> [ClaimRollupView] {
        var views: [ClaimRollupView] = []
        for item in items {
            views.append(toClaimRollupView(item))
        }
        return views
    }

    static func sumClaimRollupView(_ view: ClaimRollupView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedCeiling + parsedDiscount + Double(parsedUpdatedAt)
    }
}
