import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped closure milestone.
    final class CappedClosureMilestoneView {
        var code: String
        var name: String
        var allergy: String
        var title: String
        var ownerID: String
        var region: String
        var ratioText: String
        var statusLabel: String

        init(code: String, name: String, allergy: String, title: String, ownerID: String, region: String, ratioText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.title = title
            self.ownerID = ownerID
            self.region = region
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedClosureMilestoneView(_ item: CappedClosureMilestone) -> CappedClosureMilestoneView {
        return CappedClosureMilestoneView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            allergy: item.allergy,
            title: Kit.Text.truncate(item.title, limit: 40),
            ownerID: item.ownerID,
            region: item.region,
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedClosureMilestoneViews(_ items: [CappedClosureMilestone]) -> [CappedClosureMilestoneView] {
        var views: [CappedClosureMilestoneView] = []
        for item in items {
            views.append(toCappedClosureMilestoneView(item))
        }
        return views
    }

    static func sumCappedClosureMilestoneView(_ view: CappedClosureMilestoneView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
