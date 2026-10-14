import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional slot record.
    final class RegionalSlotRecordView {
        var code: String
        var name: String
        var bed: String
        var costText: String
        var description: String
        var refillsText: String
        var channel: String
        var segment: String
        var startsAt: String
        var batchSizeText: String
        var category: String
        var statusLabel: String

        init(code: String, name: String, bed: String, costText: String, description: String, refillsText: String, channel: String, segment: String, startsAt: String, batchSizeText: String, category: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.bed = bed
            self.costText = costText
            self.description = description
            self.refillsText = refillsText
            self.channel = channel
            self.segment = segment
            self.startsAt = startsAt
            self.batchSizeText = batchSizeText
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalSlotRecordView(_ item: RegionalSlotRecord) -> RegionalSlotRecordView {
        return RegionalSlotRecordView(
            code: item.code,
            name: item.name,
            bed: item.bed,
            costText: String(format: "%.2f", item.cost),
            description: item.description,
            refillsText: String(item.refills),
            channel: item.channel,
            segment: item.segment,
            startsAt: String(item.startsAt),
            batchSizeText: String(item.batchSize),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalSlotRecordViews(_ items: [RegionalSlotRecord]) -> [RegionalSlotRecordView] {
        var views: [RegionalSlotRecordView] = []
        for item in items {
            views.append(toRegionalSlotRecordView(item))
        }
        return views
    }

    static func sumRegionalSlotRecordView(_ view: RegionalSlotRecordView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedCost + Double(parsedRefills) + Double(parsedStartsAt)
    }
}
