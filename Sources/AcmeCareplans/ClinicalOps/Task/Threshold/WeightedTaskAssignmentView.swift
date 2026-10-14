import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a weighted task assignment.
    final class WeightedTaskAssignmentView {
        var code: String
        var labelText: String
        var checksum: String
        var discount: String
        var capacity: String
        var encounterID: String
        var score: String
        var statusLabel: String

        init(code: String, labelText: String, checksum: String, discount: String, capacity: String, encounterID: String, score: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.checksum = checksum
            self.discount = discount
            self.capacity = capacity
            self.encounterID = encounterID
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedTaskAssignmentView(_ item: WeightedTaskAssignment) -> WeightedTaskAssignmentView {
        return WeightedTaskAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            checksum: item.checksum,
            discount: String(format: "%.2f", item.discount),
            capacity: String(item.capacity),
            encounterID: item.encounterID,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedTaskAssignmentViews(_ items: [WeightedTaskAssignment]) -> [WeightedTaskAssignmentView] {
        var views: [WeightedTaskAssignmentView] = []
        for item in items {
            views.append(toWeightedTaskAssignmentView(item))
        }
        return views
    }

    static func sumWeightedTaskAssignmentView(_ view: WeightedTaskAssignmentView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedDiscount + Double(parsedCapacity) + parsedScore
    }
}
