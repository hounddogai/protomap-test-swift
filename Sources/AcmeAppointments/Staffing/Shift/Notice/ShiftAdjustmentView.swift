import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift adjustment.
    final class ShiftAdjustmentView {
        var code: String
        var label: String
        var payer: String
        var unit: String
        var ward: String
        var diagnosisCode: String
        var locale: String
        var amount: String
        var margin: String
        var summaryText: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, label: String, payer: String, unit: String, ward: String, diagnosisCode: String, locale: String, amount: String, margin: String, summaryText: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.payer = payer
            self.unit = unit
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.locale = locale
            self.amount = amount
            self.margin = margin
            self.summaryText = summaryText
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toShiftAdjustmentView(_ item: ShiftAdjustment) -> ShiftAdjustmentView {
        return ShiftAdjustmentView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            payer: item.payer,
            unit: Kit.Text.truncate(item.unit, limit: 120),
            ward: item.ward,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            locale: item.locale,
            amount: String(format: "%.2f", item.amount),
            margin: String(format: "%.2f", item.margin),
            summaryText: item.summary,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftAdjustmentViews(_ items: [ShiftAdjustment]) -> [ShiftAdjustmentView] {
        var views: [ShiftAdjustmentView] = []
        for item in items {
            views.append(toShiftAdjustmentView(item))
        }
        return views
    }

    static func sumShiftAdjustmentView(_ view: ShiftAdjustmentView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedAmount + parsedMargin + Double(parsedExpiresAt)
    }
}
