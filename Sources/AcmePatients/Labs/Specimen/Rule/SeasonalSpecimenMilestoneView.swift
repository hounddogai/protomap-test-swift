import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a seasonal specimen milestone.
    final class SeasonalSpecimenMilestoneView {
        var codeText: String
        var titleText: String
        var acuityText: String
        var patientRefText: String
        var floorValue: String
        var limit: String
        var amount: String
        var statusLabel: String

        init(codeText: String, titleText: String, acuityText: String, patientRefText: String, floorValue: String, limit: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.acuityText = acuityText
            self.patientRefText = patientRefText
            self.floorValue = floorValue
            self.limit = limit
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalSpecimenMilestoneView(_ item: SeasonalSpecimenMilestone) -> SeasonalSpecimenMilestoneView {
        return SeasonalSpecimenMilestoneView(
            codeText: item.code,
            titleText: item.title,
            acuityText: String(item.acuity),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            limit: String(item.limit),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalSpecimenMilestoneViews(_ items: [SeasonalSpecimenMilestone]) -> [SeasonalSpecimenMilestoneView] {
        var views: [SeasonalSpecimenMilestoneView] = []
        for item in items {
            views.append(toSeasonalSpecimenMilestoneView(item))
        }
        return views
    }

    static func sumSeasonalSpecimenMilestoneView(_ view: SeasonalSpecimenMilestoneView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedAcuity) + parsedFloorValue + Double(parsedLimit)
    }
}
