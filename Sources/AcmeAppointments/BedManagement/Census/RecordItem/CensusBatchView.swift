import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census batch.
    final class CensusBatchView {
        var code: String
        var name: String
        var source: String
        var payer: String
        var currency: String
        var costText: String
        var limit: String
        var region: String
        var statusLabel: String

        init(code: String, name: String, source: String, payer: String, currency: String, costText: String, limit: String, region: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.source = source
            self.payer = payer
            self.currency = currency
            self.costText = costText
            self.limit = limit
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toCensusBatchView(_ item: CensusBatch) -> CensusBatchView {
        return CensusBatchView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            source: item.source,
            payer: Kit.Text.truncate(item.payer, limit: 120),
            currency: item.currency,
            costText: String(format: "%.2f", item.cost),
            limit: String(item.limit),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusBatchViews(_ items: [CensusBatch]) -> [CensusBatchView] {
        var views: [CensusBatchView] = []
        for item in items {
            views.append(toCensusBatchView(item))
        }
        return views
    }

    static func sumCensusBatchView(_ view: CensusBatchView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedCost + Double(parsedLimit)
    }
}
