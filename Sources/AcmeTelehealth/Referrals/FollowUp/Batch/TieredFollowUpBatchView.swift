import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered follow up batch.
    final class TieredFollowUpBatchView {
        var codeText: String
        var title: String
        var patientRef: String
        var floorValueText: String
        var batchSize: String
        var minimum: String
        var statusLabel: String

        init(codeText: String, title: String, patientRef: String, floorValueText: String, batchSize: String, minimum: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.patientRef = patientRef
            self.floorValueText = floorValueText
            self.batchSize = batchSize
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toTieredFollowUpBatchView(_ item: TieredFollowUpBatch) -> TieredFollowUpBatchView {
        return TieredFollowUpBatchView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 40),
            patientRef: item.patientRef,
            floorValueText: String(format: "%.2f", item.floorValue),
            batchSize: String(item.batchSize),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredFollowUpBatchViews(_ items: [TieredFollowUpBatch]) -> [TieredFollowUpBatchView] {
        var views: [TieredFollowUpBatchView] = []
        for item in items {
            views.append(toTieredFollowUpBatchView(item))
        }
        return views
    }

    static func sumTieredFollowUpBatchView(_ view: TieredFollowUpBatchView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedFloorValue + Double(parsedBatchSize) + parsedMinimum
    }
}
