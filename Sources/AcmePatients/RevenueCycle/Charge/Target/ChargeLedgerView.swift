import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge ledger.
    final class ChargeLedgerView {
        var codeText: String
        var title: String
        var endsAt: String
        var notesText: String
        var summaryText: String
        var ward: String
        var checksumText: String
        var cost: String
        var rate: String
        var payer: String
        var source: String
        var statusLabel: String

        init(codeText: String, title: String, endsAt: String, notesText: String, summaryText: String, ward: String, checksumText: String, cost: String, rate: String, payer: String, source: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.endsAt = endsAt
            self.notesText = notesText
            self.summaryText = summaryText
            self.ward = ward
            self.checksumText = checksumText
            self.cost = cost
            self.rate = rate
            self.payer = payer
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toChargeLedgerView(_ item: ChargeLedger) -> ChargeLedgerView {
        return ChargeLedgerView(
            codeText: item.code,
            title: item.title,
            endsAt: String(item.endsAt),
            notesText: item.notes,
            summaryText: item.summary,
            ward: item.ward,
            checksumText: item.checksum,
            cost: String(format: "%.2f", item.cost),
            rate: String(format: "%.2f", item.rate),
            payer: item.payer,
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeLedgerViews(_ items: [ChargeLedger]) -> [ChargeLedgerView] {
        var views: [ChargeLedgerView] = []
        for item in items {
            views.append(toChargeLedgerView(item))
        }
        return views
    }

    static func sumChargeLedgerView(_ view: ChargeLedgerView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedEndsAt) + parsedCost + parsedRate
    }
}
