import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary shift allocation.
    final class PrimaryShiftAllocationView {
        var code: String
        var title: String
        var pinnedText: String
        var visible: String
        var phoneText: String
        var segment: String
        var budget: String
        var archived: String
        var weightText: String
        var createdAt: String
        var statusLabel: String

        init(code: String, title: String, pinnedText: String, visible: String, phoneText: String, segment: String, budget: String, archived: String, weightText: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.pinnedText = pinnedText
            self.visible = visible
            self.phoneText = phoneText
            self.segment = segment
            self.budget = budget
            self.archived = archived
            self.weightText = weightText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryShiftAllocationView(_ item: PrimaryShiftAllocation) -> PrimaryShiftAllocationView {
        return PrimaryShiftAllocationView(
            code: item.code,
            title: item.title,
            pinnedText: "\(item.pinned)",
            visible: "\(item.visible)",
            phoneText: item.phone,
            segment: item.segment,
            budget: String(format: "%.2f", item.budget),
            archived: "\(item.archived)",
            weightText: String(format: "%.2f", item.weight),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryShiftAllocationViews(_ items: [PrimaryShiftAllocation]) -> [PrimaryShiftAllocationView] {
        var views: [PrimaryShiftAllocationView] = []
        for item in items {
            views.append(toPrimaryShiftAllocationView(item))
        }
        return views
    }

    static func sumPrimaryShiftAllocationView(_ view: PrimaryShiftAllocationView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedBudget + parsedWeight + Double(parsedCreatedAt)
    }
}
