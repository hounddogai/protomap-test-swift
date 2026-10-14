import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form agreement.
    final class ConsentFormAgreementView {
        var codeText: String
        var name: String
        var country: String
        var phone: String
        var locale: String
        var retriesText: String
        var ward: String
        var durationMinutes: String
        var notesText: String
        var statusLabel: String

        init(codeText: String, name: String, country: String, phone: String, locale: String, retriesText: String, ward: String, durationMinutes: String, notesText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.country = country
            self.phone = phone
            self.locale = locale
            self.retriesText = retriesText
            self.ward = ward
            self.durationMinutes = durationMinutes
            self.notesText = notesText
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormAgreementView(_ item: ConsentFormAgreement) -> ConsentFormAgreementView {
        return ConsentFormAgreementView(
            codeText: item.code,
            name: item.name,
            country: item.country,
            phone: item.phone,
            locale: item.locale,
            retriesText: String(item.retries),
            ward: Kit.Text.truncate(item.ward, limit: 120),
            durationMinutes: String(item.durationMinutes),
            notesText: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormAgreementViews(_ items: [ConsentFormAgreement]) -> [ConsentFormAgreementView] {
        var views: [ConsentFormAgreementView] = []
        for item in items {
            views.append(toConsentFormAgreementView(item))
        }
        return views
    }

    static func sumConsentFormAgreementView(_ view: ConsentFormAgreementView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedRetries) + Double(parsedDurationMinutes)
    }
}
