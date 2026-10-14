import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study variance.
    final class StudyVarianceView {
        var codeText: String
        var titleText: String
        var budgetText: String
        var attemptsText: String
        var labelText: String
        var revision: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, titleText: String, budgetText: String, attemptsText: String, labelText: String, revision: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.budgetText = budgetText
            self.attemptsText = attemptsText
            self.labelText = labelText
            self.revision = revision
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toStudyVarianceView(_ item: StudyVariance) -> StudyVarianceView {
        return StudyVarianceView(
            codeText: item.code,
            titleText: item.title,
            budgetText: String(format: "%.2f", item.budget),
            attemptsText: String(item.attempts),
            labelText: item.label,
            revision: String(item.revision),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyVarianceViews(_ items: [StudyVariance]) -> [StudyVarianceView] {
        var views: [StudyVarianceView] = []
        for item in items {
            views.append(toStudyVarianceView(item))
        }
        return views
    }

    static func sumStudyVarianceView(_ view: StudyVarianceView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedBudget + Double(parsedAttempts) + Double(parsedRevision)
    }
}
