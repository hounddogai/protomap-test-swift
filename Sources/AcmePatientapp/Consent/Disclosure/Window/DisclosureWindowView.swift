import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure window.
    final class DisclosureWindowView {
        var codeText: String
        var name: String
        var minimum: String
        var locale: String
        var ceiling: String
        var attempts: String
        var pinned: String
        var expiresAt: String
        var procedureCode: String
        var channel: String
        var statusLabel: String

        init(codeText: String, name: String, minimum: String, locale: String, ceiling: String, attempts: String, pinned: String, expiresAt: String, procedureCode: String, channel: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.minimum = minimum
            self.locale = locale
            self.ceiling = ceiling
            self.attempts = attempts
            self.pinned = pinned
            self.expiresAt = expiresAt
            self.procedureCode = procedureCode
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureWindowView(_ item: DisclosureWindow) -> DisclosureWindowView {
        return DisclosureWindowView(
            codeText: item.code,
            name: item.name,
            minimum: String(format: "%.2f", item.minimum),
            locale: item.locale,
            ceiling: String(format: "%.2f", item.ceiling),
            attempts: String(item.attempts),
            pinned: "\(item.pinned)",
            expiresAt: String(item.expiresAt),
            procedureCode: item.procedureCode,
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureWindowViews(_ items: [DisclosureWindow]) -> [DisclosureWindowView] {
        var views: [DisclosureWindowView] = []
        for item in items {
            views.append(toDisclosureWindowView(item))
        }
        return views
    }

    static func sumDisclosureWindowView(_ view: DisclosureWindowView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedMinimum + parsedCeiling + Double(parsedAttempts)
    }
}
