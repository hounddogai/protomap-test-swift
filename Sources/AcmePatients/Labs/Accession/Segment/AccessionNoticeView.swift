import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession notice.
    final class AccessionNoticeView {
        var code: String
        var label: String
        var timezone: String
        var refills: String
        var revision: String
        var updatedAt: String
        var externalRef: String
        var startsAt: String
        var windowDays: String
        var attemptsText: String
        var payer: String
        var statusLabel: String

        init(code: String, label: String, timezone: String, refills: String, revision: String, updatedAt: String, externalRef: String, startsAt: String, windowDays: String, attemptsText: String, payer: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.refills = refills
            self.revision = revision
            self.updatedAt = updatedAt
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.windowDays = windowDays
            self.attemptsText = attemptsText
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionNoticeView(_ item: AccessionNotice) -> AccessionNoticeView {
        return AccessionNoticeView(
            code: item.code,
            label: item.label,
            timezone: item.timezone,
            refills: String(item.refills),
            revision: String(item.revision),
            updatedAt: String(item.updatedAt),
            externalRef: item.externalRef,
            startsAt: String(item.startsAt),
            windowDays: String(item.windowDays),
            attemptsText: String(item.attempts),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionNoticeViews(_ items: [AccessionNotice]) -> [AccessionNoticeView] {
        var views: [AccessionNoticeView] = []
        for item in items {
            views.append(toAccessionNoticeView(item))
        }
        return views
    }

    static func sumAccessionNoticeView(_ view: AccessionNoticeView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedRefills) + Double(parsedRevision) + Double(parsedUpdatedAt)
    }
}
