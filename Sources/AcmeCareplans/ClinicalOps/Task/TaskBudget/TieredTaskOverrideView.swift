import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a tiered task override.
    final class TieredTaskOverrideView {
        var code: String
        var label: String
        var localeText: String
        var expiresAt: String
        var timezone: String
        var updatedAtText: String
        var bed: String
        var country: String
        var attempts: String
        var patientRef: String
        var statusLabel: String

        init(code: String, label: String, localeText: String, expiresAt: String, timezone: String, updatedAtText: String, bed: String, country: String, attempts: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.localeText = localeText
            self.expiresAt = expiresAt
            self.timezone = timezone
            self.updatedAtText = updatedAtText
            self.bed = bed
            self.country = country
            self.attempts = attempts
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toTieredTaskOverrideView(_ item: TieredTaskOverride) -> TieredTaskOverrideView {
        return TieredTaskOverrideView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            localeText: item.locale,
            expiresAt: String(item.expiresAt),
            timezone: item.timezone,
            updatedAtText: String(item.updatedAt),
            bed: item.bed,
            country: item.country,
            attempts: String(item.attempts),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredTaskOverrideViews(_ items: [TieredTaskOverride]) -> [TieredTaskOverrideView] {
        var views: [TieredTaskOverrideView] = []
        for item in items {
            views.append(toTieredTaskOverrideView(item))
        }
        return views
    }

    static func sumTieredTaskOverrideView(_ view: TieredTaskOverrideView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedUpdatedAt) + Double(parsedAttempts)
    }
}
