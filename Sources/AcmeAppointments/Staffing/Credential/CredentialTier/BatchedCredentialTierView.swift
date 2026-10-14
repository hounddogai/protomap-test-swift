import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a batched credential tier.
    final class BatchedCredentialTierView {
        var code: String
        var label: String
        var channel: String
        var title: String
        var name: String
        var quantityText: String
        var archived: String
        var ratioText: String
        var floorValue: String
        var segment: String
        var ownerID: String
        var statusLabel: String

        init(code: String, label: String, channel: String, title: String, name: String, quantityText: String, archived: String, ratioText: String, floorValue: String, segment: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.channel = channel
            self.title = title
            self.name = name
            self.quantityText = quantityText
            self.archived = archived
            self.ratioText = ratioText
            self.floorValue = floorValue
            self.segment = segment
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCredentialTierView(_ item: BatchedCredentialTier) -> BatchedCredentialTierView {
        return BatchedCredentialTierView(
            code: item.code,
            label: item.label,
            channel: item.channel,
            title: item.title,
            name: item.name,
            quantityText: String(item.quantity),
            archived: "\(item.archived)",
            ratioText: String(format: "%.2f", item.ratio),
            floorValue: String(format: "%.2f", item.floorValue),
            segment: Kit.Text.truncate(item.segment, limit: 40),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCredentialTierViews(_ items: [BatchedCredentialTier]) -> [BatchedCredentialTierView] {
        var views: [BatchedCredentialTierView] = []
        for item in items {
            views.append(toBatchedCredentialTierView(item))
        }
        return views
    }

    static func sumBatchedCredentialTierView(_ view: BatchedCredentialTierView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedQuantity) + parsedRatio + parsedFloorValue
    }
}
