import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a batched overtime entry.
    final class BatchedOvertimeEntryView {
        var code: String
        var title: String
        var budgetText: String
        var expiresAt: String
        var refills: String
        var country: String
        var floorValueText: String
        var label: String
        var statusLabel: String

        init(code: String, title: String, budgetText: String, expiresAt: String, refills: String, country: String, floorValueText: String, label: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.budgetText = budgetText
            self.expiresAt = expiresAt
            self.refills = refills
            self.country = country
            self.floorValueText = floorValueText
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedOvertimeEntryView(_ item: BatchedOvertimeEntry) -> BatchedOvertimeEntryView {
        return BatchedOvertimeEntryView(
            code: item.code,
            title: item.title,
            budgetText: String(format: "%.2f", item.budget),
            expiresAt: String(item.expiresAt),
            refills: String(item.refills),
            country: Kit.Text.truncate(item.country, limit: 40),
            floorValueText: String(format: "%.2f", item.floorValue),
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedOvertimeEntryViews(_ items: [BatchedOvertimeEntry]) -> [BatchedOvertimeEntryView] {
        var views: [BatchedOvertimeEntryView] = []
        for item in items {
            views.append(toBatchedOvertimeEntryView(item))
        }
        return views
    }

    static func sumBatchedOvertimeEntryView(_ view: BatchedOvertimeEntryView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedBudget + Double(parsedExpiresAt) + Double(parsedRefills)
    }
}
