import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary cleaning batch.
    final class PrimaryCleaningBatchView {
        var code: String
        var name: String
        var floorValueText: String
        var expiresAt: String
        var labelText: String
        var visitMinutesText: String
        var capacity: String
        var channel: String
        var payer: String
        var visible: String
        var statusLabel: String

        init(code: String, name: String, floorValueText: String, expiresAt: String, labelText: String, visitMinutesText: String, capacity: String, channel: String, payer: String, visible: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.floorValueText = floorValueText
            self.expiresAt = expiresAt
            self.labelText = labelText
            self.visitMinutesText = visitMinutesText
            self.capacity = capacity
            self.channel = channel
            self.payer = payer
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCleaningBatchView(_ item: PrimaryCleaningBatch) -> PrimaryCleaningBatchView {
        return PrimaryCleaningBatchView(
            code: item.code,
            name: item.name,
            floorValueText: String(format: "%.2f", item.floorValue),
            expiresAt: String(item.expiresAt),
            labelText: item.label,
            visitMinutesText: String(item.visitMinutes),
            capacity: String(item.capacity),
            channel: item.channel,
            payer: Kit.Text.truncate(item.payer, limit: 40),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCleaningBatchViews(_ items: [PrimaryCleaningBatch]) -> [PrimaryCleaningBatchView] {
        var views: [PrimaryCleaningBatchView] = []
        for item in items {
            views.append(toPrimaryCleaningBatchView(item))
        }
        return views
    }

    static func sumPrimaryCleaningBatchView(_ view: PrimaryCleaningBatchView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedFloorValue + Double(parsedExpiresAt) + Double(parsedVisitMinutes)
    }
}
