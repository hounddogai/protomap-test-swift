import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a seasonal disclosure ledger.
    final class SeasonalDisclosureLedgerView {
        var code: String
        var labelText: String
        var approved: String
        var copay: String
        var visibleText: String
        var rateText: String
        var expiresAt: String
        var active: String
        var statusLabel: String

        init(code: String, labelText: String, approved: String, copay: String, visibleText: String, rateText: String, expiresAt: String, active: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.approved = approved
            self.copay = copay
            self.visibleText = visibleText
            self.rateText = rateText
            self.expiresAt = expiresAt
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalDisclosureLedgerView(_ item: SeasonalDisclosureLedger) -> SeasonalDisclosureLedgerView {
        return SeasonalDisclosureLedgerView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            approved: "\(item.approved)",
            copay: String(format: "%.2f", item.copay),
            visibleText: "\(item.visible)",
            rateText: String(format: "%.2f", item.rate),
            expiresAt: String(item.expiresAt),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalDisclosureLedgerViews(_ items: [SeasonalDisclosureLedger]) -> [SeasonalDisclosureLedgerView] {
        var views: [SeasonalDisclosureLedgerView] = []
        for item in items {
            views.append(toSeasonalDisclosureLedgerView(item))
        }
        return views
    }

    static func sumSeasonalDisclosureLedgerView(_ view: SeasonalDisclosureLedgerView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedCopay + parsedRate + Double(parsedExpiresAt)
    }
}
