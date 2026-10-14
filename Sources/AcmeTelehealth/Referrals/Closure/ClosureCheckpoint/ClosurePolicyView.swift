import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure policy.
    final class ClosurePolicyView {
        var code: String
        var label: String
        var visitMinutes: String
        var notesText: String
        var floorValue: String
        var name: String
        var visible: String
        var ceiling: String
        var statusLabel: String

        init(code: String, label: String, visitMinutes: String, notesText: String, floorValue: String, name: String, visible: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.notesText = notesText
            self.floorValue = floorValue
            self.name = name
            self.visible = visible
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toClosurePolicyView(_ item: ClosurePolicy) -> ClosurePolicyView {
        return ClosurePolicyView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            visitMinutes: String(item.visitMinutes),
            notesText: item.notes,
            floorValue: String(format: "%.2f", item.floorValue),
            name: item.name,
            visible: "\(item.visible)",
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosurePolicyViews(_ items: [ClosurePolicy]) -> [ClosurePolicyView] {
        var views: [ClosurePolicyView] = []
        for item in items {
            views.append(toClosurePolicyView(item))
        }
        return views
    }

    static func sumClosurePolicyView(_ view: ClosurePolicyView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedVisitMinutes) + parsedFloorValue + parsedCeiling
    }
}
