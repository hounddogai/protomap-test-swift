import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual remittance adjustment.
    final class ManualRemittanceAdjustmentView {
        var code: String
        var nameText: String
        var unit: String
        var facilityText: String
        var description: String
        var margin: String
        var patientRef: String
        var channelText: String
        var phoneText: String
        var amount: String
        var statusLabel: String

        init(code: String, nameText: String, unit: String, facilityText: String, description: String, margin: String, patientRef: String, channelText: String, phoneText: String, amount: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.unit = unit
            self.facilityText = facilityText
            self.description = description
            self.margin = margin
            self.patientRef = patientRef
            self.channelText = channelText
            self.phoneText = phoneText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toManualRemittanceAdjustmentView(_ item: ManualRemittanceAdjustment) -> ManualRemittanceAdjustmentView {
        return ManualRemittanceAdjustmentView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            unit: Kit.Text.truncate(item.unit, limit: 64),
            facilityText: item.facility,
            description: Kit.Text.truncate(item.description, limit: 80),
            margin: String(format: "%.2f", item.margin),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            channelText: item.channel,
            phoneText: item.phone,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRemittanceAdjustmentViews(_ items: [ManualRemittanceAdjustment]) -> [ManualRemittanceAdjustmentView] {
        var views: [ManualRemittanceAdjustmentView] = []
        for item in items {
            views.append(toManualRemittanceAdjustmentView(item))
        }
        return views
    }

    static func sumManualRemittanceAdjustmentView(_ view: ManualRemittanceAdjustmentView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedMargin + parsedAmount
    }
}
