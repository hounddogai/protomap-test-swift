import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a tiered revocation rollup.
    final class TieredRevocationRollupView {
        var code: String
        var labelText: String
        var revisionText: String
        var allergy: String
        var priority: String
        var acuity: String
        var statusLabel: String

        init(code: String, labelText: String, revisionText: String, allergy: String, priority: String, acuity: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.revisionText = revisionText
            self.allergy = allergy
            self.priority = priority
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRevocationRollupView(_ item: TieredRevocationRollup) -> TieredRevocationRollupView {
        return TieredRevocationRollupView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 80),
            revisionText: String(item.revision),
            allergy: item.allergy,
            priority: String(item.priority),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRevocationRollupViews(_ items: [TieredRevocationRollup]) -> [TieredRevocationRollupView] {
        var views: [TieredRevocationRollupView] = []
        for item in items {
            views.append(toTieredRevocationRollupView(item))
        }
        return views
    }

    static func sumTieredRevocationRollupView(_ view: TieredRevocationRollupView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedRevision) + Double(parsedPriority) + Double(parsedAcuity)
    }
}
