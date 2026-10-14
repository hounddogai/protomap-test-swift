import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a regional modality slot.
    final class RegionalModalitySlotView {
        var code: String
        var label: String
        var graceDaysText: String
        var acuity: String
        var ownerID: String
        var ratioText: String
        var reviewer: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, label: String, graceDaysText: String, acuity: String, ownerID: String, ratioText: String, reviewer: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.graceDaysText = graceDaysText
            self.acuity = acuity
            self.ownerID = ownerID
            self.ratioText = ratioText
            self.reviewer = reviewer
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalModalitySlotView(_ item: RegionalModalitySlot) -> RegionalModalitySlotView {
        return RegionalModalitySlotView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            graceDaysText: String(item.graceDays),
            acuity: String(item.acuity),
            ownerID: item.ownerID,
            ratioText: String(format: "%.2f", item.ratio),
            reviewer: item.reviewer,
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalModalitySlotViews(_ items: [RegionalModalitySlot]) -> [RegionalModalitySlotView] {
        var views: [RegionalModalitySlotView] = []
        for item in items {
            views.append(toRegionalModalitySlotView(item))
        }
        return views
    }

    static func sumRegionalModalitySlotView(_ view: RegionalModalitySlotView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedAcuity) + parsedRatio
    }
}
