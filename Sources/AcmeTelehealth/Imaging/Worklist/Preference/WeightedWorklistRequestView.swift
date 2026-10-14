import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a weighted worklist request.
    final class WeightedWorklistRequestView {
        var codeText: String
        var title: String
        var visible: String
        var notesText: String
        var startsAtText: String
        var ceiling: String
        var encounterID: String
        var active: String
        var statusLabel: String

        init(codeText: String, title: String, visible: String, notesText: String, startsAtText: String, ceiling: String, encounterID: String, active: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.visible = visible
            self.notesText = notesText
            self.startsAtText = startsAtText
            self.ceiling = ceiling
            self.encounterID = encounterID
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedWorklistRequestView(_ item: WeightedWorklistRequest) -> WeightedWorklistRequestView {
        return WeightedWorklistRequestView(
            codeText: item.code,
            title: item.title,
            visible: "\(item.visible)",
            notesText: item.notes,
            startsAtText: String(item.startsAt),
            ceiling: String(format: "%.2f", item.ceiling),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedWorklistRequestViews(_ items: [WeightedWorklistRequest]) -> [WeightedWorklistRequestView] {
        var views: [WeightedWorklistRequestView] = []
        for item in items {
            views.append(toWeightedWorklistRequestView(item))
        }
        return views
    }

    static func sumWeightedWorklistRequestView(_ view: WeightedWorklistRequestView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedStartsAt) + parsedCeiling
    }
}
