import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback bed board adjustment.
    final class FallbackBedBoardAdjustmentView {
        var code: String
        var label: String
        var maximumText: String
        var encounterID: String
        var retriesText: String
        var archivedText: String
        var batchSize: String
        var wardText: String
        var windowDays: String
        var statusLabel: String

        init(code: String, label: String, maximumText: String, encounterID: String, retriesText: String, archivedText: String, batchSize: String, wardText: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.maximumText = maximumText
            self.encounterID = encounterID
            self.retriesText = retriesText
            self.archivedText = archivedText
            self.batchSize = batchSize
            self.wardText = wardText
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackBedBoardAdjustmentView(_ item: FallbackBedBoardAdjustment) -> FallbackBedBoardAdjustmentView {
        return FallbackBedBoardAdjustmentView(
            code: item.code,
            label: item.label,
            maximumText: String(format: "%.2f", item.maximum),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            retriesText: String(item.retries),
            archivedText: "\(item.archived)",
            batchSize: String(item.batchSize),
            wardText: Kit.Text.truncate(item.ward, limit: 80),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackBedBoardAdjustmentViews(_ items: [FallbackBedBoardAdjustment]) -> [FallbackBedBoardAdjustmentView] {
        var views: [FallbackBedBoardAdjustmentView] = []
        for item in items {
            views.append(toFallbackBedBoardAdjustmentView(item))
        }
        return views
    }

    static func sumFallbackBedBoardAdjustmentView(_ view: FallbackBedBoardAdjustmentView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedMaximum + Double(parsedRetries) + Double(parsedBatchSize)
    }
}
