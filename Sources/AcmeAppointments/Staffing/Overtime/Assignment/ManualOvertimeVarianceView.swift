import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a manual overtime variance.
    final class ManualOvertimeVarianceView {
        var code: String
        var label: String
        var phoneText: String
        var limit: String
        var amountText: String
        var active: String
        var acuityText: String
        var statusLabel: String

        init(code: String, label: String, phoneText: String, limit: String, amountText: String, active: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.phoneText = phoneText
            self.limit = limit
            self.amountText = amountText
            self.active = active
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toManualOvertimeVarianceView(_ item: ManualOvertimeVariance) -> ManualOvertimeVarianceView {
        return ManualOvertimeVarianceView(
            code: item.code,
            label: item.label,
            phoneText: Kit.Text.truncate(item.phone, limit: 64),
            limit: String(item.limit),
            amountText: String(format: "%.2f", item.amount),
            active: "\(item.active)",
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualOvertimeVarianceViews(_ items: [ManualOvertimeVariance]) -> [ManualOvertimeVarianceView] {
        var views: [ManualOvertimeVarianceView] = []
        for item in items {
            views.append(toManualOvertimeVarianceView(item))
        }
        return views
    }

    static func sumManualOvertimeVarianceView(_ view: ManualOvertimeVarianceView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedLimit) + parsedAmount + Double(parsedAcuity)
    }
}
