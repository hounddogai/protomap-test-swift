import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy ledger.
    final class ProxyLedgerView {
        var code: String
        var label: String
        var unitText: String
        var minimum: String
        var statusLabel: String

        init(code: String, label: String, unitText: String, minimum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.unitText = unitText
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toProxyLedgerView(_ item: ProxyLedger) -> ProxyLedgerView {
        return ProxyLedgerView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 80),
            unitText: item.unit,
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyLedgerViews(_ items: [ProxyLedger]) -> [ProxyLedgerView] {
        var views: [ProxyLedgerView] = []
        for item in items {
            views.append(toProxyLedgerView(item))
        }
        return views
    }

    static func sumProxyLedgerView(_ view: ProxyLedgerView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
