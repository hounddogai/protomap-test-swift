import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding request.
    final class RoundingRequestView {
        var codeText: String
        var label: String
        var quantity: String
        var amount: String
        var minimumText: String
        var createdAt: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, quantity: String, amount: String, minimumText: String, createdAt: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.quantity = quantity
            self.amount = amount
            self.minimumText = minimumText
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingRequestView(_ item: RoundingRequest) -> RoundingRequestView {
        return RoundingRequestView(
            codeText: item.code,
            label: item.label,
            quantity: String(item.quantity),
            amount: String(format: "%.2f", item.amount),
            minimumText: String(format: "%.2f", item.minimum),
            createdAt: String(item.createdAt),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingRequestViews(_ items: [RoundingRequest]) -> [RoundingRequestView] {
        var views: [RoundingRequestView] = []
        for item in items {
            views.append(toRoundingRequestView(item))
        }
        return views
    }

    static func sumRoundingRequestView(_ view: RoundingRequestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedQuantity) + parsedAmount + parsedMinimum
    }
}
