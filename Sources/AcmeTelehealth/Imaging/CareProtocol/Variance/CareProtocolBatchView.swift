import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol batch.
    final class CareProtocolBatchView {
        var code: String
        var name: String
        var amountText: String
        var maximum: String
        var clinicianIDText: String
        var checksumText: String
        var margin: String
        var floorValueText: String
        var minimumText: String
        var externalRef: String
        var scoreText: String
        var statusLabel: String

        init(code: String, name: String, amountText: String, maximum: String, clinicianIDText: String, checksumText: String, margin: String, floorValueText: String, minimumText: String, externalRef: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.amountText = amountText
            self.maximum = maximum
            self.clinicianIDText = clinicianIDText
            self.checksumText = checksumText
            self.margin = margin
            self.floorValueText = floorValueText
            self.minimumText = minimumText
            self.externalRef = externalRef
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolBatchView(_ item: CareProtocolBatch) -> CareProtocolBatchView {
        return CareProtocolBatchView(
            code: item.code,
            name: item.name,
            amountText: String(format: "%.2f", item.amount),
            maximum: String(format: "%.2f", item.maximum),
            clinicianIDText: item.clinicianID,
            checksumText: item.checksum,
            margin: String(format: "%.2f", item.margin),
            floorValueText: String(format: "%.2f", item.floorValue),
            minimumText: String(format: "%.2f", item.minimum),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolBatchViews(_ items: [CareProtocolBatch]) -> [CareProtocolBatchView] {
        var views: [CareProtocolBatchView] = []
        for item in items {
            views.append(toCareProtocolBatchView(item))
        }
        return views
    }

    static func sumCareProtocolBatchView(_ view: CareProtocolBatchView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedAmount + parsedMaximum + parsedMargin
    }
}
