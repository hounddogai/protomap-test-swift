import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding assignment.
    final class RoundingAssignmentView {
        var codeText: String
        var name: String
        var thresholdText: String
        var acuity: String
        var cost: String
        var notes: String
        var createdAt: String
        var updatedAt: String
        var statusLabel: String

        init(codeText: String, name: String, thresholdText: String, acuity: String, cost: String, notes: String, createdAt: String, updatedAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.thresholdText = thresholdText
            self.acuity = acuity
            self.cost = cost
            self.notes = notes
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingAssignmentView(_ item: RoundingAssignment) -> RoundingAssignmentView {
        return RoundingAssignmentView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            thresholdText: String(format: "%.2f", item.threshold),
            acuity: String(item.acuity),
            cost: String(format: "%.2f", item.cost),
            notes: Kit.Text.truncate(item.notes, limit: 40),
            createdAt: String(item.createdAt),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingAssignmentViews(_ items: [RoundingAssignment]) -> [RoundingAssignmentView] {
        var views: [RoundingAssignmentView] = []
        for item in items {
            views.append(toRoundingAssignmentView(item))
        }
        return views
    }

    static func sumRoundingAssignmentView(_ view: RoundingAssignmentView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedThreshold + Double(parsedAcuity) + parsedCost
    }
}
