import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled discharge plan adjustment.
    final class ScheduledDischargePlanAdjustmentView {
        var codeText: String
        var title: String
        var durationMinutesText: String
        var contactEmailText: String
        var quantity: String
        var diagnosisCode: String
        var discount: String
        var locale: String
        var statusLabel: String

        init(codeText: String, title: String, durationMinutesText: String, contactEmailText: String, quantity: String, diagnosisCode: String, discount: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.durationMinutesText = durationMinutesText
            self.contactEmailText = contactEmailText
            self.quantity = quantity
            self.diagnosisCode = diagnosisCode
            self.discount = discount
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledDischargePlanAdjustmentView(_ item: ScheduledDischargePlanAdjustment) -> ScheduledDischargePlanAdjustmentView {
        return ScheduledDischargePlanAdjustmentView(
            codeText: item.code,
            title: item.title,
            durationMinutesText: String(item.durationMinutes),
            contactEmailText: item.contactEmail,
            quantity: String(item.quantity),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            discount: String(format: "%.2f", item.discount),
            locale: Kit.Text.truncate(item.locale, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledDischargePlanAdjustmentViews(_ items: [ScheduledDischargePlanAdjustment]) -> [ScheduledDischargePlanAdjustmentView] {
        var views: [ScheduledDischargePlanAdjustmentView] = []
        for item in items {
            views.append(toScheduledDischargePlanAdjustmentView(item))
        }
        return views
    }

    static func sumScheduledDischargePlanAdjustmentView(_ view: ScheduledDischargePlanAdjustmentView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedQuantity) + parsedDiscount
    }
}
