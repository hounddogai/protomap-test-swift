import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered overtime override.
    final class TieredOvertimeOverrideView {
        var codeText: String
        var nameText: String
        var priorityText: String
        var approvedText: String
        var procedureCodeText: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, nameText: String, priorityText: String, approvedText: String, procedureCodeText: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.priorityText = priorityText
            self.approvedText = approvedText
            self.procedureCodeText = procedureCodeText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toTieredOvertimeOverrideView(_ item: TieredOvertimeOverride) -> TieredOvertimeOverrideView {
        return TieredOvertimeOverrideView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            priorityText: String(item.priority),
            approvedText: "\(item.approved)",
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredOvertimeOverrideViews(_ items: [TieredOvertimeOverride]) -> [TieredOvertimeOverrideView] {
        var views: [TieredOvertimeOverrideView] = []
        for item in items {
            views.append(toTieredOvertimeOverrideView(item))
        }
        return views
    }

    static func sumTieredOvertimeOverrideView(_ view: TieredOvertimeOverrideView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedPriority) + parsedFloorValue
    }
}
