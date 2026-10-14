import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback bed board target.
    final class FallbackBedBoardTargetView {
        var code: String
        var labelText: String
        var amountText: String
        var currencyText: String
        var durationMinutesText: String
        var quantity: String
        var description: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, labelText: String, amountText: String, currencyText: String, durationMinutesText: String, quantity: String, description: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.amountText = amountText
            self.currencyText = currencyText
            self.durationMinutesText = durationMinutesText
            self.quantity = quantity
            self.description = description
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackBedBoardTargetView(_ item: FallbackBedBoardTarget) -> FallbackBedBoardTargetView {
        return FallbackBedBoardTargetView(
            code: item.code,
            labelText: item.label,
            amountText: String(format: "%.2f", item.amount),
            currencyText: item.currency,
            durationMinutesText: String(item.durationMinutes),
            quantity: String(item.quantity),
            description: item.description,
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackBedBoardTargetViews(_ items: [FallbackBedBoardTarget]) -> [FallbackBedBoardTargetView] {
        var views: [FallbackBedBoardTargetView] = []
        for item in items {
            views.append(toFallbackBedBoardTargetView(item))
        }
        return views
    }

    static func sumFallbackBedBoardTargetView(_ view: FallbackBedBoardTargetView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedAmount + Double(parsedDurationMinutes) + Double(parsedQuantity)
    }
}
