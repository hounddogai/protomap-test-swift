import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a batched dispense policy.
    final class BatchedDispensePolicyView {
        var code: String
        var title: String
        var cost: String
        var bed: String
        var reviewer: String
        var approved: String
        var payer: String
        var notes: String
        var phone: String
        var statusLabel: String

        init(code: String, title: String, cost: String, bed: String, reviewer: String, approved: String, payer: String, notes: String, phone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.cost = cost
            self.bed = bed
            self.reviewer = reviewer
            self.approved = approved
            self.payer = payer
            self.notes = notes
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDispensePolicyView(_ item: BatchedDispensePolicy) -> BatchedDispensePolicyView {
        return BatchedDispensePolicyView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 120),
            cost: String(format: "%.2f", item.cost),
            bed: Kit.Text.truncate(item.bed, limit: 40),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            approved: "\(item.approved)",
            payer: Kit.Text.truncate(item.payer, limit: 40),
            notes: item.notes,
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDispensePolicyViews(_ items: [BatchedDispensePolicy]) -> [BatchedDispensePolicyView] {
        var views: [BatchedDispensePolicyView] = []
        for item in items {
            views.append(toBatchedDispensePolicyView(item))
        }
        return views
    }

    static func sumBatchedDispensePolicyView(_ view: BatchedDispensePolicyView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
