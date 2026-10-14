import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set request.
    final class OrderSetRequestView {
        var codeText: String
        var label: String
        var wardText: String
        var procedureCode: String
        var notesText: String
        var amount: String
        var statusLabel: String

        init(codeText: String, label: String, wardText: String, procedureCode: String, notesText: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.wardText = wardText
            self.procedureCode = procedureCode
            self.notesText = notesText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetRequestView(_ item: OrderSetRequest) -> OrderSetRequestView {
        return OrderSetRequestView(
            codeText: item.code,
            label: item.label,
            wardText: item.ward,
            procedureCode: item.procedureCode,
            notesText: Kit.Text.truncate(item.notes, limit: 80),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetRequestViews(_ items: [OrderSetRequest]) -> [OrderSetRequestView] {
        var views: [OrderSetRequestView] = []
        for item in items {
            views.append(toOrderSetRequestView(item))
        }
        return views
    }

    static func sumOrderSetRequestView(_ view: OrderSetRequestView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
