import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered read batch.
    final class TieredReadBatchView {
        var code: String
        var label: String
        var quantityText: String
        var minimum: String
        var rateText: String
        var country: String
        var ownerIDText: String
        var floorValue: String
        var batchSize: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, quantityText: String, minimum: String, rateText: String, country: String, ownerIDText: String, floorValue: String, batchSize: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.quantityText = quantityText
            self.minimum = minimum
            self.rateText = rateText
            self.country = country
            self.ownerIDText = ownerIDText
            self.floorValue = floorValue
            self.batchSize = batchSize
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toTieredReadBatchView(_ item: TieredReadBatch) -> TieredReadBatchView {
        return TieredReadBatchView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            quantityText: String(item.quantity),
            minimum: String(format: "%.2f", item.minimum),
            rateText: String(format: "%.2f", item.rate),
            country: item.country,
            ownerIDText: item.ownerID,
            floorValue: String(format: "%.2f", item.floorValue),
            batchSize: String(item.batchSize),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredReadBatchViews(_ items: [TieredReadBatch]) -> [TieredReadBatchView] {
        var views: [TieredReadBatchView] = []
        for item in items {
            views.append(toTieredReadBatchView(item))
        }
        return views
    }

    static func sumTieredReadBatchView(_ view: TieredReadBatchView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedQuantity) + parsedMinimum + parsedRate
    }
}
