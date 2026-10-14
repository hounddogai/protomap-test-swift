import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global assessment milestone.
    final class GlobalAssessmentMilestoneView {
        var code: String
        var title: String
        var ceiling: String
        var versionText: String
        var threshold: String
        var description: String
        var externalRefText: String
        var statusLabel: String

        init(code: String, title: String, ceiling: String, versionText: String, threshold: String, description: String, externalRefText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.versionText = versionText
            self.threshold = threshold
            self.description = description
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalAssessmentMilestoneView(_ item: GlobalAssessmentMilestone) -> GlobalAssessmentMilestoneView {
        return GlobalAssessmentMilestoneView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            versionText: String(item.version),
            threshold: String(format: "%.2f", item.threshold),
            description: item.description,
            externalRefText: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalAssessmentMilestoneViews(_ items: [GlobalAssessmentMilestone]) -> [GlobalAssessmentMilestoneView] {
        var views: [GlobalAssessmentMilestoneView] = []
        for item in items {
            views.append(toGlobalAssessmentMilestoneView(item))
        }
        return views
    }

    static func sumGlobalAssessmentMilestoneView(_ view: GlobalAssessmentMilestoneView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedCeiling + Double(parsedVersion) + parsedThreshold
    }
}
