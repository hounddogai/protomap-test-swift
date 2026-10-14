import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered care protocol ledger.
    final class TieredCareProtocolLedgerView {
        var code: String
        var name: String
        var cost: String
        var reviewer: String
        var retriesText: String
        var encounterID: String
        var acuity: String
        var statusLabel: String

        init(code: String, name: String, cost: String, reviewer: String, retriesText: String, encounterID: String, acuity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.cost = cost
            self.reviewer = reviewer
            self.retriesText = retriesText
            self.encounterID = encounterID
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toTieredCareProtocolLedgerView(_ item: TieredCareProtocolLedger) -> TieredCareProtocolLedgerView {
        return TieredCareProtocolLedgerView(
            code: item.code,
            name: item.name,
            cost: String(format: "%.2f", item.cost),
            reviewer: item.reviewer,
            retriesText: String(item.retries),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredCareProtocolLedgerViews(_ items: [TieredCareProtocolLedger]) -> [TieredCareProtocolLedgerView] {
        var views: [TieredCareProtocolLedgerView] = []
        for item in items {
            views.append(toTieredCareProtocolLedgerView(item))
        }
        return views
    }

    static func sumTieredCareProtocolLedgerView(_ view: TieredCareProtocolLedgerView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedCost + Double(parsedRetries) + Double(parsedAcuity)
    }
}
