import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool notice.
    final class FloatPoolNoticeView {
        var codeText: String
        var title: String
        var patientRef: String
        var active: String
        var country: String
        var diagnosisCode: String
        var timezone: String
        var externalRef: String
        var ownerID: String
        var reviewer: String
        var limit: String
        var statusLabel: String

        init(codeText: String, title: String, patientRef: String, active: String, country: String, diagnosisCode: String, timezone: String, externalRef: String, ownerID: String, reviewer: String, limit: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.patientRef = patientRef
            self.active = active
            self.country = country
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.externalRef = externalRef
            self.ownerID = ownerID
            self.reviewer = reviewer
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolNoticeView(_ item: FloatPoolNotice) -> FloatPoolNoticeView {
        return FloatPoolNoticeView(
            codeText: item.code,
            title: item.title,
            patientRef: item.patientRef,
            active: "\(item.active)",
            country: item.country,
            diagnosisCode: item.diagnosisCode,
            timezone: item.timezone,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 120),
            ownerID: item.ownerID,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolNoticeViews(_ items: [FloatPoolNotice]) -> [FloatPoolNoticeView] {
        var views: [FloatPoolNoticeView] = []
        for item in items {
            views.append(toFloatPoolNoticeView(item))
        }
        return views
    }

    static func sumFloatPoolNoticeView(_ view: FloatPoolNoticeView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
