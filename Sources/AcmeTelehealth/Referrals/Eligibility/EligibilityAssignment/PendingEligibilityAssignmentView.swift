import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending eligibility assignment.
    final class PendingEligibilityAssignmentView {
        var code: String
        var titleText: String
        var patientRefText: String
        var scoreText: String
        var nameText: String
        var unit: String
        var rate: String
        var revisionText: String
        var ceilingText: String
        var retriesText: String
        var statusLabel: String

        init(code: String, titleText: String, patientRefText: String, scoreText: String, nameText: String, unit: String, rate: String, revisionText: String, ceilingText: String, retriesText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.patientRefText = patientRefText
            self.scoreText = scoreText
            self.nameText = nameText
            self.unit = unit
            self.rate = rate
            self.revisionText = revisionText
            self.ceilingText = ceilingText
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingEligibilityAssignmentView(_ item: PendingEligibilityAssignment) -> PendingEligibilityAssignmentView {
        return PendingEligibilityAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 120),
            scoreText: String(format: "%.2f", item.score),
            nameText: item.name,
            unit: item.unit,
            rate: String(format: "%.2f", item.rate),
            revisionText: String(item.revision),
            ceilingText: String(format: "%.2f", item.ceiling),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingEligibilityAssignmentViews(_ items: [PendingEligibilityAssignment]) -> [PendingEligibilityAssignmentView] {
        var views: [PendingEligibilityAssignmentView] = []
        for item in items {
            views.append(toPendingEligibilityAssignmentView(item))
        }
        return views
    }

    static func sumPendingEligibilityAssignmentView(_ view: PendingEligibilityAssignmentView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedScore + parsedRate + Double(parsedRevision)
    }
}
