import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a tiered cleaning claim.
    final class TieredCleaningClaimView {
        var codeText: String
        var labelText: String
        var patientRef: String
        var externalRefText: String
        var attempts: String
        var name: String
        var ratioText: String
        var procedureCodeText: String
        var statusLabel: String

        init(codeText: String, labelText: String, patientRef: String, externalRefText: String, attempts: String, name: String, ratioText: String, procedureCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.patientRef = patientRef
            self.externalRefText = externalRefText
            self.attempts = attempts
            self.name = name
            self.ratioText = ratioText
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredCleaningClaimView(_ item: TieredCleaningClaim) -> TieredCleaningClaimView {
        return TieredCleaningClaimView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            patientRef: item.patientRef,
            externalRefText: item.externalRef,
            attempts: String(item.attempts),
            name: item.name,
            ratioText: String(format: "%.2f", item.ratio),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredCleaningClaimViews(_ items: [TieredCleaningClaim]) -> [TieredCleaningClaimView] {
        var views: [TieredCleaningClaimView] = []
        for item in items {
            views.append(toTieredCleaningClaimView(item))
        }
        return views
    }

    static func sumTieredCleaningClaimView(_ view: TieredCleaningClaimView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedAttempts) + parsedRatio
    }
}
