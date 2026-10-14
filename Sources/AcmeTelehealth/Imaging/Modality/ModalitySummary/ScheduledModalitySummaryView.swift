import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a scheduled modality summary.
    final class ScheduledModalitySummaryView {
        var codeText: String
        var name: String
        var checksum: String
        var weight: String
        var ownerID: String
        var quantity: String
        var ward: String
        var rate: String
        var contactEmail: String
        var batchSize: String
        var channel: String
        var statusLabel: String

        init(codeText: String, name: String, checksum: String, weight: String, ownerID: String, quantity: String, ward: String, rate: String, contactEmail: String, batchSize: String, channel: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.checksum = checksum
            self.weight = weight
            self.ownerID = ownerID
            self.quantity = quantity
            self.ward = ward
            self.rate = rate
            self.contactEmail = contactEmail
            self.batchSize = batchSize
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledModalitySummaryView(_ item: ScheduledModalitySummary) -> ScheduledModalitySummaryView {
        return ScheduledModalitySummaryView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            checksum: item.checksum,
            weight: String(format: "%.2f", item.weight),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            quantity: String(item.quantity),
            ward: Kit.Text.truncate(item.ward, limit: 64),
            rate: String(format: "%.2f", item.rate),
            contactEmail: item.contactEmail,
            batchSize: String(item.batchSize),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledModalitySummaryViews(_ items: [ScheduledModalitySummary]) -> [ScheduledModalitySummaryView] {
        var views: [ScheduledModalitySummaryView] = []
        for item in items {
            views.append(toScheduledModalitySummaryView(item))
        }
        return views
    }

    static func sumScheduledModalitySummaryView(_ view: ScheduledModalitySummaryView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedWeight + Double(parsedQuantity) + parsedRate
    }
}
