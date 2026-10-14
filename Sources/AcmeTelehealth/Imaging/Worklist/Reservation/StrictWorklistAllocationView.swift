import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict worklist allocation.
    final class StrictWorklistAllocationView {
        var code: String
        var name: String
        var pinned: String
        var createdAtText: String
        var amountText: String
        var description: String
        var statusLabel: String

        init(code: String, name: String, pinned: String, createdAtText: String, amountText: String, description: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.createdAtText = createdAtText
            self.amountText = amountText
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toStrictWorklistAllocationView(_ item: StrictWorklistAllocation) -> StrictWorklistAllocationView {
        return StrictWorklistAllocationView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 40),
            pinned: "\(item.pinned)",
            createdAtText: String(item.createdAt),
            amountText: String(format: "%.2f", item.amount),
            description: Kit.Text.truncate(item.description, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictWorklistAllocationViews(_ items: [StrictWorklistAllocation]) -> [StrictWorklistAllocationView] {
        var views: [StrictWorklistAllocationView] = []
        for item in items {
            views.append(toStrictWorklistAllocationView(item))
        }
        return views
    }

    static func sumStrictWorklistAllocationView(_ view: StrictWorklistAllocationView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedCreatedAt) + parsedAmount
    }
}
