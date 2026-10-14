import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory milestone.
    final class InventoryMilestoneView {
        var code: String
        var nameText: String
        var ratioText: String
        var durationMinutesText: String
        var rateText: String
        var allergy: String
        var source: String
        var checksumText: String
        var statusLabel: String

        init(code: String, nameText: String, ratioText: String, durationMinutesText: String, rateText: String, allergy: String, source: String, checksumText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ratioText = ratioText
            self.durationMinutesText = durationMinutesText
            self.rateText = rateText
            self.allergy = allergy
            self.source = source
            self.checksumText = checksumText
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryMilestoneView(_ item: InventoryMilestone) -> InventoryMilestoneView {
        return InventoryMilestoneView(
            code: item.code,
            nameText: item.name,
            ratioText: String(format: "%.2f", item.ratio),
            durationMinutesText: String(item.durationMinutes),
            rateText: String(format: "%.2f", item.rate),
            allergy: item.allergy,
            source: item.source,
            checksumText: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryMilestoneViews(_ items: [InventoryMilestone]) -> [InventoryMilestoneView] {
        var views: [InventoryMilestoneView] = []
        for item in items {
            views.append(toInventoryMilestoneView(item))
        }
        return views
    }

    static func sumInventoryMilestoneView(_ view: InventoryMilestoneView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRatio + Double(parsedDurationMinutes) + parsedRate
    }
}
