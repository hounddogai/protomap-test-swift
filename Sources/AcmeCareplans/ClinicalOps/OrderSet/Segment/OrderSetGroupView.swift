import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set group.
    final class OrderSetGroupView {
        var code: String
        var title: String
        var endsAt: String
        var batchSizeText: String
        var ownerID: String
        var active: String
        var region: String
        var ward: String
        var margin: String
        var statusLabel: String

        init(code: String, title: String, endsAt: String, batchSizeText: String, ownerID: String, active: String, region: String, ward: String, margin: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.batchSizeText = batchSizeText
            self.ownerID = ownerID
            self.active = active
            self.region = region
            self.ward = ward
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetGroupView(_ item: OrderSetGroup) -> OrderSetGroupView {
        return OrderSetGroupView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            endsAt: String(item.endsAt),
            batchSizeText: String(item.batchSize),
            ownerID: item.ownerID,
            active: "\(item.active)",
            region: item.region,
            ward: item.ward,
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetGroupViews(_ items: [OrderSetGroup]) -> [OrderSetGroupView] {
        var views: [OrderSetGroupView] = []
        for item in items {
            views.append(toOrderSetGroupView(item))
        }
        return views
    }

    static func sumOrderSetGroupView(_ view: OrderSetGroupView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedBatchSize) + parsedMargin
    }
}
