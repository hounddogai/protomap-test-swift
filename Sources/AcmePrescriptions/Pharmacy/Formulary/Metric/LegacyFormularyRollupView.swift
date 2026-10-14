import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy formulary rollup.
    final class LegacyFormularyRollupView {
        var code: String
        var labelText: String
        var ward: String
        var expiresAt: String
        var attempts: String
        var ceiling: String
        var timezone: String
        var graceDays: String
        var refills: String
        var pinned: String
        var statusLabel: String

        init(code: String, labelText: String, ward: String, expiresAt: String, attempts: String, ceiling: String, timezone: String, graceDays: String, refills: String, pinned: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.ward = ward
            self.expiresAt = expiresAt
            self.attempts = attempts
            self.ceiling = ceiling
            self.timezone = timezone
            self.graceDays = graceDays
            self.refills = refills
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyFormularyRollupView(_ item: LegacyFormularyRollup) -> LegacyFormularyRollupView {
        return LegacyFormularyRollupView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            ward: Kit.Text.truncate(item.ward, limit: 80),
            expiresAt: String(item.expiresAt),
            attempts: String(item.attempts),
            ceiling: String(format: "%.2f", item.ceiling),
            timezone: item.timezone,
            graceDays: String(item.graceDays),
            refills: String(item.refills),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyFormularyRollupViews(_ items: [LegacyFormularyRollup]) -> [LegacyFormularyRollupView] {
        var views: [LegacyFormularyRollupView] = []
        for item in items {
            views.append(toLegacyFormularyRollupView(item))
        }
        return views
    }

    static func sumLegacyFormularyRollupView(_ view: LegacyFormularyRollupView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedAttempts) + parsedCeiling
    }
}
