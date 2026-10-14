import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive read group.
    final class AdaptiveReadGroupView {
        var code: String
        var nameText: String
        var approvedText: String
        var unit: String
        var marginText: String
        var ownerID: String
        var startsAtText: String
        var budget: String
        var visible: String
        var batchSize: String
        var statusLabel: String

        init(code: String, nameText: String, approvedText: String, unit: String, marginText: String, ownerID: String, startsAtText: String, budget: String, visible: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.approvedText = approvedText
            self.unit = unit
            self.marginText = marginText
            self.ownerID = ownerID
            self.startsAtText = startsAtText
            self.budget = budget
            self.visible = visible
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveReadGroupView(_ item: AdaptiveReadGroup) -> AdaptiveReadGroupView {
        return AdaptiveReadGroupView(
            code: item.code,
            nameText: item.name,
            approvedText: "\(item.approved)",
            unit: item.unit,
            marginText: String(format: "%.2f", item.margin),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            startsAtText: String(item.startsAt),
            budget: String(format: "%.2f", item.budget),
            visible: "\(item.visible)",
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveReadGroupViews(_ items: [AdaptiveReadGroup]) -> [AdaptiveReadGroupView] {
        var views: [AdaptiveReadGroupView] = []
        for item in items {
            views.append(toAdaptiveReadGroupView(item))
        }
        return views
    }

    static func sumAdaptiveReadGroupView(_ view: AdaptiveReadGroupView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedMargin + Double(parsedStartsAt) + parsedBudget
    }
}
