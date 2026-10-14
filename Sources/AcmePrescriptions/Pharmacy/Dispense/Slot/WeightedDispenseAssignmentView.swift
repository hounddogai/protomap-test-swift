import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted dispense assignment.
    final class WeightedDispenseAssignmentView {
        var code: String
        var label: String
        var visitMinutes: String
        var createdAt: String
        var bed: String
        var retries: String
        var expiresAtText: String
        var budgetText: String
        var amountText: String
        var statusLabel: String

        init(code: String, label: String, visitMinutes: String, createdAt: String, bed: String, retries: String, expiresAtText: String, budgetText: String, amountText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.createdAt = createdAt
            self.bed = bed
            self.retries = retries
            self.expiresAtText = expiresAtText
            self.budgetText = budgetText
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedDispenseAssignmentView(_ item: WeightedDispenseAssignment) -> WeightedDispenseAssignmentView {
        return WeightedDispenseAssignmentView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            visitMinutes: String(item.visitMinutes),
            createdAt: String(item.createdAt),
            bed: item.bed,
            retries: String(item.retries),
            expiresAtText: String(item.expiresAt),
            budgetText: String(format: "%.2f", item.budget),
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedDispenseAssignmentViews(_ items: [WeightedDispenseAssignment]) -> [WeightedDispenseAssignmentView] {
        var views: [WeightedDispenseAssignmentView] = []
        for item in items {
            views.append(toWeightedDispenseAssignmentView(item))
        }
        return views
    }

    static func sumWeightedDispenseAssignmentView(_ view: WeightedDispenseAssignmentView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedCreatedAt) + Double(parsedRetries)
    }
}
