import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census checkpoint.
    final class CensusCheckpointView {
        var code: String
        var label: String
        var floorValue: String
        var visitMinutes: String
        var category: String
        var budgetText: String
        var ceiling: String
        var retries: String
        var statusLabel: String

        init(code: String, label: String, floorValue: String, visitMinutes: String, category: String, budgetText: String, ceiling: String, retries: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.visitMinutes = visitMinutes
            self.category = category
            self.budgetText = budgetText
            self.ceiling = ceiling
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toCensusCheckpointView(_ item: CensusCheckpoint) -> CensusCheckpointView {
        return CensusCheckpointView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            visitMinutes: String(item.visitMinutes),
            category: Kit.Text.truncate(item.category, limit: 40),
            budgetText: String(format: "%.2f", item.budget),
            ceiling: String(format: "%.2f", item.ceiling),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusCheckpointViews(_ items: [CensusCheckpoint]) -> [CensusCheckpointView] {
        var views: [CensusCheckpointView] = []
        for item in items {
            views.append(toCensusCheckpointView(item))
        }
        return views
    }

    static func sumCensusCheckpointView(_ view: CensusCheckpointView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedFloorValue + Double(parsedVisitMinutes) + parsedBudget
    }
}
