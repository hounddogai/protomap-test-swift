import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default revocation milestone.
    final class DefaultRevocationMilestoneView {
        var code: String
        var title: String
        var allergy: String
        var limitText: String
        var ratioText: String
        var statusLabel: String

        init(code: String, title: String, allergy: String, limitText: String, ratioText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.limitText = limitText
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultRevocationMilestoneView(_ item: DefaultRevocationMilestone) -> DefaultRevocationMilestoneView {
        return DefaultRevocationMilestoneView(
            code: item.code,
            title: item.title,
            allergy: item.allergy,
            limitText: String(item.limit),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultRevocationMilestoneViews(_ items: [DefaultRevocationMilestone]) -> [DefaultRevocationMilestoneView] {
        var views: [DefaultRevocationMilestoneView] = []
        for item in items {
            views.append(toDefaultRevocationMilestoneView(item))
        }
        return views
    }

    static func sumDefaultRevocationMilestoneView(_ view: DefaultRevocationMilestoneView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedLimit) + parsedRatio
    }
}
