import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted inventory assignment.
    final class WeightedInventoryAssignmentView {
        var code: String
        var title: String
        var encounterID: String
        var timezone: String
        var visible: String
        var sequence: String
        var region: String
        var capacity: String
        var pinned: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, title: String, encounterID: String, timezone: String, visible: String, sequence: String, region: String, capacity: String, pinned: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.timezone = timezone
            self.visible = visible
            self.sequence = sequence
            self.region = region
            self.capacity = capacity
            self.pinned = pinned
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedInventoryAssignmentView(_ item: WeightedInventoryAssignment) -> WeightedInventoryAssignmentView {
        return WeightedInventoryAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            encounterID: item.encounterID,
            timezone: item.timezone,
            visible: "\(item.visible)",
            sequence: String(item.sequence),
            region: Kit.Text.truncate(item.region, limit: 40),
            capacity: String(item.capacity),
            pinned: "\(item.pinned)",
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedInventoryAssignmentViews(_ items: [WeightedInventoryAssignment]) -> [WeightedInventoryAssignmentView] {
        var views: [WeightedInventoryAssignmentView] = []
        for item in items {
            views.append(toWeightedInventoryAssignmentView(item))
        }
        return views
    }

    static func sumWeightedInventoryAssignmentView(_ view: WeightedInventoryAssignmentView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedSequence) + Double(parsedCapacity)
    }
}
