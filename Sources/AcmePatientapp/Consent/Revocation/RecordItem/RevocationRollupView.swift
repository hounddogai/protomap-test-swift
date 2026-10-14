import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation rollup.
    final class RevocationRollupView {
        var code: String
        var label: String
        var acuity: String
        var minimum: String
        var bedText: String
        var ownerID: String
        var statusLabel: String

        init(code: String, label: String, acuity: String, minimum: String, bedText: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.minimum = minimum
            self.bedText = bedText
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationRollupView(_ item: RevocationRollup) -> RevocationRollupView {
        return RevocationRollupView(
            code: item.code,
            label: item.label,
            acuity: String(item.acuity),
            minimum: String(format: "%.2f", item.minimum),
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationRollupViews(_ items: [RevocationRollup]) -> [RevocationRollupView] {
        var views: [RevocationRollupView] = []
        for item in items {
            views.append(toRevocationRollupView(item))
        }
        return views
    }

    static func sumRevocationRollupView(_ view: RevocationRollupView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedAcuity) + parsedMinimum
    }
}
