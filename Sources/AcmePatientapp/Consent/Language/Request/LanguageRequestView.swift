import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language request.
    final class LanguageRequestView {
        var code: String
        var titleText: String
        var phone: String
        var country: String
        var specialty: String
        var ceiling: String
        var contactEmail: String
        var weight: String
        var statusLabel: String

        init(code: String, titleText: String, phone: String, country: String, specialty: String, ceiling: String, contactEmail: String, weight: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.phone = phone
            self.country = country
            self.specialty = specialty
            self.ceiling = ceiling
            self.contactEmail = contactEmail
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageRequestView(_ item: LanguageRequest) -> LanguageRequestView {
        return LanguageRequestView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            phone: Kit.Text.truncate(item.phone, limit: 120),
            country: item.country,
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageRequestViews(_ items: [LanguageRequest]) -> [LanguageRequestView] {
        var views: [LanguageRequestView] = []
        for item in items {
            views.append(toLanguageRequestView(item))
        }
        return views
    }

    static func sumLanguageRequestView(_ view: LanguageRequestView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedCeiling + parsedWeight
    }
}
