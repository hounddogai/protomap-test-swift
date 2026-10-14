import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization milestone.
    final class AuthorizationMilestoneView {
        var codeText: String
        var title: String
        var facilityText: String
        var categoryText: String
        var retries: String
        var ratio: String
        var statusLabel: String

        init(codeText: String, title: String, facilityText: String, categoryText: String, retries: String, ratio: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.facilityText = facilityText
            self.categoryText = categoryText
            self.retries = retries
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationMilestoneView(_ item: AuthorizationMilestone) -> AuthorizationMilestoneView {
        return AuthorizationMilestoneView(
            codeText: item.code,
            title: item.title,
            facilityText: item.facility,
            categoryText: item.category,
            retries: String(item.retries),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationMilestoneViews(_ items: [AuthorizationMilestone]) -> [AuthorizationMilestoneView] {
        var views: [AuthorizationMilestoneView] = []
        for item in items {
            views.append(toAuthorizationMilestoneView(item))
        }
        return views
    }

    static func sumAuthorizationMilestoneView(_ view: AuthorizationMilestoneView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedRetries) + parsedRatio
    }
}
