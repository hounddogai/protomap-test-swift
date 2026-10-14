import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel segment.
    final class PanelSegmentView {
        var codeText: String
        var label: String
        var capacity: String
        var thresholdText: String
        var budget: String
        var statusLabel: String

        init(codeText: String, label: String, capacity: String, thresholdText: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.capacity = capacity
            self.thresholdText = thresholdText
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toPanelSegmentView(_ item: PanelSegment) -> PanelSegmentView {
        return PanelSegmentView(
            codeText: item.code,
            label: item.label,
            capacity: String(item.capacity),
            thresholdText: String(format: "%.2f", item.threshold),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelSegmentViews(_ items: [PanelSegment]) -> [PanelSegmentView] {
        var views: [PanelSegmentView] = []
        for item in items {
            views.append(toPanelSegmentView(item))
        }
        return views
    }

    static func sumPanelSegmentView(_ view: PanelSegmentView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedCapacity) + parsedThreshold + parsedBudget
    }
}
