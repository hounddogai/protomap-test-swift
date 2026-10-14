import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel allocation.
    final class PanelAllocationView {
        var code: String
        var title: String
        var ward: String
        var priority: String
        var active: String
        var budget: String
        var createdAt: String
        var externalRef: String
        var approved: String
        var statusLabel: String

        init(code: String, title: String, ward: String, priority: String, active: String, budget: String, createdAt: String, externalRef: String, approved: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ward = ward
            self.priority = priority
            self.active = active
            self.budget = budget
            self.createdAt = createdAt
            self.externalRef = externalRef
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toPanelAllocationView(_ item: PanelAllocation) -> PanelAllocationView {
        return PanelAllocationView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            ward: item.ward,
            priority: String(item.priority),
            active: "\(item.active)",
            budget: String(format: "%.2f", item.budget),
            createdAt: String(item.createdAt),
            externalRef: item.externalRef,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelAllocationViews(_ items: [PanelAllocation]) -> [PanelAllocationView] {
        var views: [PanelAllocationView] = []
        for item in items {
            views.append(toPanelAllocationView(item))
        }
        return views
    }

    static func sumPanelAllocationView(_ view: PanelAllocationView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedPriority) + parsedBudget + Double(parsedCreatedAt)
    }
}
