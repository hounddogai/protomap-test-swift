import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped consent form notice.
    final class CappedConsentFormNoticeView {
        var code: String
        var title: String
        var revision: String
        var sourceText: String
        var createdAt: String
        var category: String
        var attempts: String
        var statusLabel: String

        init(code: String, title: String, revision: String, sourceText: String, createdAt: String, category: String, attempts: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revision = revision
            self.sourceText = sourceText
            self.createdAt = createdAt
            self.category = category
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toCappedConsentFormNoticeView(_ item: CappedConsentFormNotice) -> CappedConsentFormNoticeView {
        return CappedConsentFormNoticeView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 120),
            revision: String(item.revision),
            sourceText: Kit.Text.truncate(item.source, limit: 64),
            createdAt: String(item.createdAt),
            category: Kit.Text.truncate(item.category, limit: 40),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedConsentFormNoticeViews(_ items: [CappedConsentFormNotice]) -> [CappedConsentFormNoticeView] {
        var views: [CappedConsentFormNoticeView] = []
        for item in items {
            views.append(toCappedConsentFormNoticeView(item))
        }
        return views
    }

    static func sumCappedConsentFormNoticeView(_ view: CappedConsentFormNoticeView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedRevision) + Double(parsedCreatedAt) + Double(parsedAttempts)
    }
}
