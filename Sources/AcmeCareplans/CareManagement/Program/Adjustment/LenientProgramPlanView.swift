import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a lenient program plan.
    final class LenientProgramPlanView {
        var codeText: String
        var nameText: String
        var timezone: String
        var score: String
        var revision: String
        var attemptsText: String
        var statusLabel: String

        init(codeText: String, nameText: String, timezone: String, score: String, revision: String, attemptsText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.timezone = timezone
            self.score = score
            self.revision = revision
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientProgramPlanView(_ item: LenientProgramPlan) -> LenientProgramPlanView {
        return LenientProgramPlanView(
            codeText: item.code,
            nameText: item.name,
            timezone: item.timezone,
            score: String(format: "%.2f", item.score),
            revision: String(item.revision),
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientProgramPlanViews(_ items: [LenientProgramPlan]) -> [LenientProgramPlanView] {
        var views: [LenientProgramPlanView] = []
        for item in items {
            views.append(toLenientProgramPlanView(item))
        }
        return views
    }

    static func sumLenientProgramPlanView(_ view: LenientProgramPlanView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedScore + Double(parsedRevision) + Double(parsedAttempts)
    }
}
