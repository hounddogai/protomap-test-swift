import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a capped recall assignment.
    final class CappedRecallAssignmentView {
        var code: String
        var title: String
        var copay: String
        var specialty: String
        var rate: String
        var scoreText: String
        var minimum: String
        var revisionText: String
        var ownerIDText: String
        var statusLabel: String

        init(code: String, title: String, copay: String, specialty: String, rate: String, scoreText: String, minimum: String, revisionText: String, ownerIDText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.copay = copay
            self.specialty = specialty
            self.rate = rate
            self.scoreText = scoreText
            self.minimum = minimum
            self.revisionText = revisionText
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedRecallAssignmentView(_ item: CappedRecallAssignment) -> CappedRecallAssignmentView {
        return CappedRecallAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            copay: String(format: "%.2f", item.copay),
            specialty: Kit.Text.truncate(item.specialty, limit: 80),
            rate: String(format: "%.2f", item.rate),
            scoreText: String(format: "%.2f", item.score),
            minimum: String(format: "%.2f", item.minimum),
            revisionText: String(item.revision),
            ownerIDText: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedRecallAssignmentViews(_ items: [CappedRecallAssignment]) -> [CappedRecallAssignmentView] {
        var views: [CappedRecallAssignmentView] = []
        for item in items {
            views.append(toCappedRecallAssignmentView(item))
        }
        return views
    }

    static func sumCappedRecallAssignmentView(_ view: CappedRecallAssignmentView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedCopay + parsedRate + parsedScore
    }
}
