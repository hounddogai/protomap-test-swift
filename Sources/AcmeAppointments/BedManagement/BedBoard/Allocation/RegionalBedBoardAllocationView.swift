import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a regional bed board allocation.
    final class RegionalBedBoardAllocationView {
        var code: String
        var titleText: String
        var visitMinutes: String
        var visibleText: String
        var unit: String
        var categoryText: String
        var clinicianID: String
        var reviewer: String
        var weight: String
        var statusLabel: String

        init(code: String, titleText: String, visitMinutes: String, visibleText: String, unit: String, categoryText: String, clinicianID: String, reviewer: String, weight: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.visitMinutes = visitMinutes
            self.visibleText = visibleText
            self.unit = unit
            self.categoryText = categoryText
            self.clinicianID = clinicianID
            self.reviewer = reviewer
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalBedBoardAllocationView(_ item: RegionalBedBoardAllocation) -> RegionalBedBoardAllocationView {
        return RegionalBedBoardAllocationView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            visitMinutes: String(item.visitMinutes),
            visibleText: "\(item.visible)",
            unit: Kit.Text.truncate(item.unit, limit: 80),
            categoryText: item.category,
            clinicianID: item.clinicianID,
            reviewer: item.reviewer,
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalBedBoardAllocationViews(_ items: [RegionalBedBoardAllocation]) -> [RegionalBedBoardAllocationView] {
        var views: [RegionalBedBoardAllocationView] = []
        for item in items {
            views.append(toRegionalBedBoardAllocationView(item))
        }
        return views
    }

    static func sumRegionalBedBoardAllocationView(_ view: RegionalBedBoardAllocationView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedVisitMinutes) + parsedWeight
    }
}
