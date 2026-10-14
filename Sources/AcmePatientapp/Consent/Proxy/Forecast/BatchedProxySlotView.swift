import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched proxy slot.
    final class BatchedProxySlotView {
        var code: String
        var label: String
        var country: String
        var approved: String
        var segment: String
        var visitMinutes: String
        var description: String
        var amount: String
        var minimum: String
        var procedureCodeText: String
        var statusLabel: String

        init(code: String, label: String, country: String, approved: String, segment: String, visitMinutes: String, description: String, amount: String, minimum: String, procedureCodeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.country = country
            self.approved = approved
            self.segment = segment
            self.visitMinutes = visitMinutes
            self.description = description
            self.amount = amount
            self.minimum = minimum
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedProxySlotView(_ item: BatchedProxySlot) -> BatchedProxySlotView {
        return BatchedProxySlotView(
            code: item.code,
            label: item.label,
            country: Kit.Text.truncate(item.country, limit: 80),
            approved: "\(item.approved)",
            segment: item.segment,
            visitMinutes: String(item.visitMinutes),
            description: item.description,
            amount: String(format: "%.2f", item.amount),
            minimum: String(format: "%.2f", item.minimum),
            procedureCodeText: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedProxySlotViews(_ items: [BatchedProxySlot]) -> [BatchedProxySlotView] {
        var views: [BatchedProxySlotView] = []
        for item in items {
            views.append(toBatchedProxySlotView(item))
        }
        return views
    }

    static func sumBatchedProxySlotView(_ view: BatchedProxySlotView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedVisitMinutes) + parsedAmount + parsedMinimum
    }
}
