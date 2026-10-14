import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy result agreement.
    final class LegacyResultAgreementView {
        var codeText: String
        var title: String
        var segment: String
        var marginText: String
        var clinicianID: String
        var sourceText: String
        var contactEmail: String
        var statusLabel: String

        init(codeText: String, title: String, segment: String, marginText: String, clinicianID: String, sourceText: String, contactEmail: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.segment = segment
            self.marginText = marginText
            self.clinicianID = clinicianID
            self.sourceText = sourceText
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyResultAgreementView(_ item: LegacyResultAgreement) -> LegacyResultAgreementView {
        return LegacyResultAgreementView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 120),
            segment: item.segment,
            marginText: String(format: "%.2f", item.margin),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 120),
            sourceText: item.source,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyResultAgreementViews(_ items: [LegacyResultAgreement]) -> [LegacyResultAgreementView] {
        var views: [LegacyResultAgreementView] = []
        for item in items {
            views.append(toLegacyResultAgreementView(item))
        }
        return views
    }

    static func sumLegacyResultAgreementView(_ view: LegacyResultAgreementView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
