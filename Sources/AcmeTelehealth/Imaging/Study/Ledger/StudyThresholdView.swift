import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study threshold.
    final class StudyThresholdView {
        var code: String
        var name: String
        var clinicianIDText: String
        var limit: String
        var procedureCodeText: String
        var priorityText: String
        var region: String
        var reviewerText: String
        var visibleText: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, clinicianIDText: String, limit: String, procedureCodeText: String, priorityText: String, region: String, reviewerText: String, visibleText: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.clinicianIDText = clinicianIDText
            self.limit = limit
            self.procedureCodeText = procedureCodeText
            self.priorityText = priorityText
            self.region = region
            self.reviewerText = reviewerText
            self.visibleText = visibleText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toStudyThresholdView(_ item: StudyThreshold) -> StudyThresholdView {
        return StudyThresholdView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 40),
            limit: String(item.limit),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 64),
            priorityText: String(item.priority),
            region: Kit.Text.truncate(item.region, limit: 120),
            reviewerText: item.reviewer,
            visibleText: "\(item.visible)",
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyThresholdViews(_ items: [StudyThreshold]) -> [StudyThresholdView] {
        var views: [StudyThresholdView] = []
        for item in items {
            views.append(toStudyThresholdView(item))
        }
        return views
    }

    static func sumStudyThresholdView(_ view: StudyThresholdView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedLimit) + Double(parsedPriority)
    }
}
