import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global census ledger.
    final class GlobalCensusLedgerView {
        var code: String
        var label: String
        var specialty: String
        var expiresAtText: String
        var summary: String
        var statusLabel: String

        init(code: String, label: String, specialty: String, expiresAtText: String, summary: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.expiresAtText = expiresAtText
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCensusLedgerView(_ item: GlobalCensusLedger) -> GlobalCensusLedgerView {
        return GlobalCensusLedgerView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 64),
            specialty: item.specialty,
            expiresAtText: String(item.expiresAt),
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCensusLedgerViews(_ items: [GlobalCensusLedger]) -> [GlobalCensusLedgerView] {
        var views: [GlobalCensusLedgerView] = []
        for item in items {
            views.append(toGlobalCensusLedgerView(item))
        }
        return views
    }

    static func sumGlobalCensusLedgerView(_ view: GlobalCensusLedgerView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
