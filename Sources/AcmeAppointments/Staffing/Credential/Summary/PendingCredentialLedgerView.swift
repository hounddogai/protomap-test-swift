import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a pending credential ledger.
    final class PendingCredentialLedgerView {
        var code: String
        var name: String
        var visitMinutes: String
        var copayText: String
        var localeText: String
        var phoneText: String
        var summaryText: String
        var statusLabel: String

        init(code: String, name: String, visitMinutes: String, copayText: String, localeText: String, phoneText: String, summaryText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.copayText = copayText
            self.localeText = localeText
            self.phoneText = phoneText
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCredentialLedgerView(_ item: PendingCredentialLedger) -> PendingCredentialLedgerView {
        return PendingCredentialLedgerView(
            code: item.code,
            name: item.name,
            visitMinutes: String(item.visitMinutes),
            copayText: String(format: "%.2f", item.copay),
            localeText: Kit.Text.truncate(item.locale, limit: 80),
            phoneText: item.phone,
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCredentialLedgerViews(_ items: [PendingCredentialLedger]) -> [PendingCredentialLedgerView] {
        var views: [PendingCredentialLedgerView] = []
        for item in items {
            views.append(toPendingCredentialLedgerView(item))
        }
        return views
    }

    static func sumPendingCredentialLedgerView(_ view: PendingCredentialLedgerView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedVisitMinutes) + parsedCopay
    }
}
