import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global care protocol digest.
    final class GlobalCareProtocolDigestView {
        var code: String
        var titleText: String
        var acuity: String
        var rateText: String
        var graceDaysText: String
        var contactEmailText: String
        var startsAtText: String
        var summary: String
        var statusLabel: String

        init(code: String, titleText: String, acuity: String, rateText: String, graceDaysText: String, contactEmailText: String, startsAtText: String, summary: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.acuity = acuity
            self.rateText = rateText
            self.graceDaysText = graceDaysText
            self.contactEmailText = contactEmailText
            self.startsAtText = startsAtText
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCareProtocolDigestView(_ item: GlobalCareProtocolDigest) -> GlobalCareProtocolDigestView {
        return GlobalCareProtocolDigestView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            acuity: String(item.acuity),
            rateText: String(format: "%.2f", item.rate),
            graceDaysText: String(item.graceDays),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 120),
            startsAtText: String(item.startsAt),
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCareProtocolDigestViews(_ items: [GlobalCareProtocolDigest]) -> [GlobalCareProtocolDigestView] {
        var views: [GlobalCareProtocolDigestView] = []
        for item in items {
            views.append(toGlobalCareProtocolDigestView(item))
        }
        return views
    }

    static func sumGlobalCareProtocolDigestView(_ view: GlobalCareProtocolDigestView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedAcuity) + parsedRate + Double(parsedGraceDays)
    }
}
