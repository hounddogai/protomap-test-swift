import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach score.
    final class OutreachScoreView {
        var code: String
        var label: String
        var discountText: String
        var bed: String
        var clinicianID: String
        var updatedAtText: String
        var graceDays: String
        var floorValueText: String
        var unit: String
        var amountText: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, label: String, discountText: String, bed: String, clinicianID: String, updatedAtText: String, graceDays: String, floorValueText: String, unit: String, amountText: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discountText = discountText
            self.bed = bed
            self.clinicianID = clinicianID
            self.updatedAtText = updatedAtText
            self.graceDays = graceDays
            self.floorValueText = floorValueText
            self.unit = unit
            self.amountText = amountText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachScoreView(_ item: OutreachScore) -> OutreachScoreView {
        return OutreachScoreView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            discountText: String(format: "%.2f", item.discount),
            bed: item.bed,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 120),
            updatedAtText: String(item.updatedAt),
            graceDays: String(item.graceDays),
            floorValueText: String(format: "%.2f", item.floorValue),
            unit: item.unit,
            amountText: String(format: "%.2f", item.amount),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachScoreViews(_ items: [OutreachScore]) -> [OutreachScoreView] {
        var views: [OutreachScoreView] = []
        for item in items {
            views.append(toOutreachScoreView(item))
        }
        return views
    }

    static func sumOutreachScoreView(_ view: OutreachScoreView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedDiscount + Double(parsedUpdatedAt) + Double(parsedGraceDays)
    }
}
