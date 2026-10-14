import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict shift threshold.
    final class StrictShiftThresholdView {
        var codeText: String
        var labelText: String
        var cost: String
        var visitMinutesText: String
        var wardText: String
        var unitText: String
        var visible: String
        var priorityText: String
        var retries: String
        var nameText: String
        var checksum: String
        var statusLabel: String

        init(codeText: String, labelText: String, cost: String, visitMinutesText: String, wardText: String, unitText: String, visible: String, priorityText: String, retries: String, nameText: String, checksum: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.cost = cost
            self.visitMinutesText = visitMinutesText
            self.wardText = wardText
            self.unitText = unitText
            self.visible = visible
            self.priorityText = priorityText
            self.retries = retries
            self.nameText = nameText
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toStrictShiftThresholdView(_ item: StrictShiftThreshold) -> StrictShiftThresholdView {
        return StrictShiftThresholdView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            cost: String(format: "%.2f", item.cost),
            visitMinutesText: String(item.visitMinutes),
            wardText: item.ward,
            unitText: item.unit,
            visible: "\(item.visible)",
            priorityText: String(item.priority),
            retries: String(item.retries),
            nameText: item.name,
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictShiftThresholdViews(_ items: [StrictShiftThreshold]) -> [StrictShiftThresholdView] {
        var views: [StrictShiftThresholdView] = []
        for item in items {
            views.append(toStrictShiftThresholdView(item))
        }
        return views
    }

    static func sumStrictShiftThresholdView(_ view: StrictShiftThresholdView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedCost + Double(parsedVisitMinutes) + Double(parsedPriority)
    }
}
