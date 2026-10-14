import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global transfer assignment.
    final class GlobalTransferAssignmentView {
        var codeText: String
        var name: String
        var capacity: String
        var patientRefText: String
        var unit: String
        var minimum: String
        var statusLabel: String

        init(codeText: String, name: String, capacity: String, patientRefText: String, unit: String, minimum: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.capacity = capacity
            self.patientRefText = patientRefText
            self.unit = unit
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalTransferAssignmentView(_ item: GlobalTransferAssignment) -> GlobalTransferAssignmentView {
        return GlobalTransferAssignmentView(
            codeText: item.code,
            name: item.name,
            capacity: String(item.capacity),
            patientRefText: item.patientRef,
            unit: item.unit,
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalTransferAssignmentViews(_ items: [GlobalTransferAssignment]) -> [GlobalTransferAssignmentView] {
        var views: [GlobalTransferAssignmentView] = []
        for item in items {
            views.append(toGlobalTransferAssignmentView(item))
        }
        return views
    }

    static func sumGlobalTransferAssignmentView(_ view: GlobalTransferAssignmentView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedCapacity) + parsedMinimum
    }
}
