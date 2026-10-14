import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a seasonal disclosure digest.
    final class SeasonalDisclosureDigestView {
        var code: String
        var title: String
        var phoneText: String
        var copay: String
        var durationMinutes: String
        var updatedAtText: String
        var budget: String
        var bedText: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, title: String, phoneText: String, copay: String, durationMinutes: String, updatedAtText: String, budget: String, bedText: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.phoneText = phoneText
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.updatedAtText = updatedAtText
            self.budget = budget
            self.bedText = bedText
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalDisclosureDigestView(_ item: SeasonalDisclosureDigest) -> SeasonalDisclosureDigestView {
        return SeasonalDisclosureDigestView(
            code: item.code,
            title: item.title,
            phoneText: Kit.Text.truncate(item.phone, limit: 80),
            copay: String(format: "%.2f", item.copay),
            durationMinutes: String(item.durationMinutes),
            updatedAtText: String(item.updatedAt),
            budget: String(format: "%.2f", item.budget),
            bedText: item.bed,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalDisclosureDigestViews(_ items: [SeasonalDisclosureDigest]) -> [SeasonalDisclosureDigestView] {
        var views: [SeasonalDisclosureDigestView] = []
        for item in items {
            views.append(toSeasonalDisclosureDigestView(item))
        }
        return views
    }

    static func sumSeasonalDisclosureDigestView(_ view: SeasonalDisclosureDigestView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedCopay + Double(parsedDurationMinutes) + Double(parsedUpdatedAt)
    }
}
