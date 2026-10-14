import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census assignment.
    final class CensusAssignmentView {
        var code: String
        var titleText: String
        var budget: String
        var ownerID: String
        var batchSize: String
        var active: String
        var refills: String
        var minimum: String
        var windowDays: String
        var allergyText: String
        var statusLabel: String

        init(code: String, titleText: String, budget: String, ownerID: String, batchSize: String, active: String, refills: String, minimum: String, windowDays: String, allergyText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.budget = budget
            self.ownerID = ownerID
            self.batchSize = batchSize
            self.active = active
            self.refills = refills
            self.minimum = minimum
            self.windowDays = windowDays
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toCensusAssignmentView(_ item: CensusAssignment) -> CensusAssignmentView {
        return CensusAssignmentView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            budget: String(format: "%.2f", item.budget),
            ownerID: item.ownerID,
            batchSize: String(item.batchSize),
            active: "\(item.active)",
            refills: String(item.refills),
            minimum: String(format: "%.2f", item.minimum),
            windowDays: String(item.windowDays),
            allergyText: Kit.Text.truncate(item.allergy, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusAssignmentViews(_ items: [CensusAssignment]) -> [CensusAssignmentView] {
        var views: [CensusAssignmentView] = []
        for item in items {
            views.append(toCensusAssignmentView(item))
        }
        return views
    }

    static func sumCensusAssignmentView(_ view: CensusAssignmentView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedBudget + Double(parsedBatchSize) + Double(parsedRefills)
    }
}
