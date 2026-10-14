import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal modality quota.
    final class SeasonalModalityQuotaView {
        var codeText: String
        var label: String
        var floorValue: String
        var rateText: String
        var acuity: String
        var budget: String
        var patientRefText: String
        var categoryText: String
        var statusLabel: String

        init(codeText: String, label: String, floorValue: String, rateText: String, acuity: String, budget: String, patientRefText: String, categoryText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.floorValue = floorValue
            self.rateText = rateText
            self.acuity = acuity
            self.budget = budget
            self.patientRefText = patientRefText
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalModalityQuotaView(_ item: SeasonalModalityQuota) -> SeasonalModalityQuotaView {
        return SeasonalModalityQuotaView(
            codeText: item.code,
            label: item.label,
            floorValue: String(format: "%.2f", item.floorValue),
            rateText: String(format: "%.2f", item.rate),
            acuity: String(item.acuity),
            budget: String(format: "%.2f", item.budget),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 80),
            categoryText: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalModalityQuotaViews(_ items: [SeasonalModalityQuota]) -> [SeasonalModalityQuotaView] {
        var views: [SeasonalModalityQuotaView] = []
        for item in items {
            views.append(toSeasonalModalityQuotaView(item))
        }
        return views
    }

    static func sumSeasonalModalityQuotaView(_ view: SeasonalModalityQuotaView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedFloorValue + parsedRate + Double(parsedAcuity)
    }
}
