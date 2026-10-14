import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a scheduled acuity plan allocation.
    final class ScheduledAcuityPlanAllocationView {
        var code: String
        var label: String
        var specialty: String
        var nameText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, label: String, specialty: String, nameText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.nameText = nameText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledAcuityPlanAllocationView(_ item: ScheduledAcuityPlanAllocation) -> ScheduledAcuityPlanAllocationView {
        return ScheduledAcuityPlanAllocationView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            specialty: item.specialty,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledAcuityPlanAllocationViews(_ items: [ScheduledAcuityPlanAllocation]) -> [ScheduledAcuityPlanAllocationView] {
        var views: [ScheduledAcuityPlanAllocationView] = []
        for item in items {
            views.append(toScheduledAcuityPlanAllocationView(item))
        }
        return views
    }

    static func sumScheduledAcuityPlanAllocationView(_ view: ScheduledAcuityPlanAllocationView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
