import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result score.
    final class ResultScoreView {
        var code: String
        var nameText: String
        var phone: String
        var patientRefText: String
        var revision: String
        var statusLabel: String

        init(code: String, nameText: String, phone: String, patientRefText: String, revision: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.phone = phone
            self.patientRefText = patientRefText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toResultScoreView(_ item: ResultScore) -> ResultScoreView {
        return ResultScoreView(
            code: item.code,
            nameText: item.name,
            phone: Kit.Text.truncate(item.phone, limit: 64),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultScoreViews(_ items: [ResultScore]) -> [ResultScoreView] {
        var views: [ResultScoreView] = []
        for item in items {
            views.append(toResultScoreView(item))
        }
        return views
    }

    static func sumResultScoreView(_ view: ResultScoreView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
