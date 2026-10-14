import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime adjustment.
    final class OvertimeAdjustmentView {
        var code: String
        var label: String
        var startsAt: String
        var clinicianIDText: String
        var discountText: String
        var regionText: String
        var durationMinutesText: String
        var procedureCodeText: String
        var statusLabel: String

        init(code: String, label: String, startsAt: String, clinicianIDText: String, discountText: String, regionText: String, durationMinutesText: String, procedureCodeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.clinicianIDText = clinicianIDText
            self.discountText = discountText
            self.regionText = regionText
            self.durationMinutesText = durationMinutesText
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeAdjustmentView(_ item: OvertimeAdjustment) -> OvertimeAdjustmentView {
        return OvertimeAdjustmentView(
            code: item.code,
            label: item.label,
            startsAt: String(item.startsAt),
            clinicianIDText: item.clinicianID,
            discountText: String(format: "%.2f", item.discount),
            regionText: item.region,
            durationMinutesText: String(item.durationMinutes),
            procedureCodeText: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeAdjustmentViews(_ items: [OvertimeAdjustment]) -> [OvertimeAdjustmentView] {
        var views: [OvertimeAdjustmentView] = []
        for item in items {
            views.append(toOvertimeAdjustmentView(item))
        }
        return views
    }

    static func sumOvertimeAdjustmentView(_ view: OvertimeAdjustmentView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedStartsAt) + parsedDiscount + Double(parsedDurationMinutes)
    }
}
