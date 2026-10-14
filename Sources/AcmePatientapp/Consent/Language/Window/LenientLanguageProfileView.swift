import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient language profile.
    final class LenientLanguageProfileView {
        var codeText: String
        var title: String
        var rate: String
        var expiresAt: String
        var windowDays: String
        var contactEmail: String
        var dosageMg: String
        var endsAtText: String
        var ownerID: String
        var regionText: String
        var limitText: String
        var statusLabel: String

        init(codeText: String, title: String, rate: String, expiresAt: String, windowDays: String, contactEmail: String, dosageMg: String, endsAtText: String, ownerID: String, regionText: String, limitText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.rate = rate
            self.expiresAt = expiresAt
            self.windowDays = windowDays
            self.contactEmail = contactEmail
            self.dosageMg = dosageMg
            self.endsAtText = endsAtText
            self.ownerID = ownerID
            self.regionText = regionText
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientLanguageProfileView(_ item: LenientLanguageProfile) -> LenientLanguageProfileView {
        return LenientLanguageProfileView(
            codeText: item.code,
            title: item.title,
            rate: String(format: "%.2f", item.rate),
            expiresAt: String(item.expiresAt),
            windowDays: String(item.windowDays),
            contactEmail: item.contactEmail,
            dosageMg: String(format: "%.2f", item.dosageMg),
            endsAtText: String(item.endsAt),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            regionText: item.region,
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientLanguageProfileViews(_ items: [LenientLanguageProfile]) -> [LenientLanguageProfileView] {
        var views: [LenientLanguageProfileView] = []
        for item in items {
            views.append(toLenientLanguageProfileView(item))
        }
        return views
    }

    static func sumLenientLanguageProfileView(_ view: LenientLanguageProfileView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedRate + Double(parsedExpiresAt) + Double(parsedWindowDays)
    }
}
