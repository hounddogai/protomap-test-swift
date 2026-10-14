import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census ledger.
    final class CensusLedgerView {
        var code: String
        var name: String
        var diagnosisCode: String
        var cost: String
        var quantityText: String
        var priority: String
        var maximum: String
        var channel: String
        var ownerIDText: String
        var statusLabel: String

        init(code: String, name: String, diagnosisCode: String, cost: String, quantityText: String, priority: String, maximum: String, channel: String, ownerIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.cost = cost
            self.quantityText = quantityText
            self.priority = priority
            self.maximum = maximum
            self.channel = channel
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toCensusLedgerView(_ item: CensusLedger) -> CensusLedgerView {
        return CensusLedgerView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 120),
            diagnosisCode: item.diagnosisCode,
            cost: String(format: "%.2f", item.cost),
            quantityText: String(item.quantity),
            priority: String(item.priority),
            maximum: String(format: "%.2f", item.maximum),
            channel: item.channel,
            ownerIDText: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusLedgerViews(_ items: [CensusLedger]) -> [CensusLedgerView] {
        var views: [CensusLedgerView] = []
        for item in items {
            views.append(toCensusLedgerView(item))
        }
        return views
    }

    static func sumCensusLedgerView(_ view: CensusLedgerView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedCost + Double(parsedQuantity) + Double(parsedPriority)
    }
}
