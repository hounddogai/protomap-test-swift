import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered care gap assignment.
    final class TieredCareGapAssignmentView {
        var code: String
        var nameText: String
        var category: String
        var budget: String
        var minimumText: String
        var facility: String
        var ownerID: String
        var statusLabel: String

        init(code: String, nameText: String, category: String, budget: String, minimumText: String, facility: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.category = category
            self.budget = budget
            self.minimumText = minimumText
            self.facility = facility
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toTieredCareGapAssignmentView(_ item: TieredCareGapAssignment) -> TieredCareGapAssignmentView {
        return TieredCareGapAssignmentView(
            code: item.code,
            nameText: item.name,
            category: item.category,
            budget: String(format: "%.2f", item.budget),
            minimumText: String(format: "%.2f", item.minimum),
            facility: item.facility,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredCareGapAssignmentViews(_ items: [TieredCareGapAssignment]) -> [TieredCareGapAssignmentView] {
        var views: [TieredCareGapAssignmentView] = []
        for item in items {
            views.append(toTieredCareGapAssignmentView(item))
        }
        return views
    }

    static func sumTieredCareGapAssignmentView(_ view: TieredCareGapAssignmentView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedBudget + parsedMinimum
    }
}
