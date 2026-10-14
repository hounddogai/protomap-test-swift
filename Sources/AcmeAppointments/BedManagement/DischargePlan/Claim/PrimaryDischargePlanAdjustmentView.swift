import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary discharge plan adjustment.
    final class PrimaryDischargePlanAdjustmentView {
        var code: String
        var title: String
        var diagnosisCode: String
        var rateText: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, title: String, diagnosisCode: String, rateText: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.rateText = rateText
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryDischargePlanAdjustmentView(_ item: PrimaryDischargePlanAdjustment) -> PrimaryDischargePlanAdjustmentView {
        return PrimaryDischargePlanAdjustmentView(
            code: item.code,
            title: item.title,
            diagnosisCode: item.diagnosisCode,
            rateText: String(format: "%.2f", item.rate),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryDischargePlanAdjustmentViews(_ items: [PrimaryDischargePlanAdjustment]) -> [PrimaryDischargePlanAdjustmentView] {
        var views: [PrimaryDischargePlanAdjustmentView] = []
        for item in items {
            views.append(toPrimaryDischargePlanAdjustmentView(item))
        }
        return views
    }

    static func sumPrimaryDischargePlanAdjustmentView(_ view: PrimaryDischargePlanAdjustmentView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedRate + Double(parsedDurationMinutes)
    }
}
