import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy exception.
    final class ProxyExceptionView {
        var code: String
        var label: String
        var minimum: String
        var archived: String
        var durationMinutes: String
        var expiresAt: String
        var copay: String
        var priority: String
        var attempts: String
        var statusLabel: String

        init(code: String, label: String, minimum: String, archived: String, durationMinutes: String, expiresAt: String, copay: String, priority: String, attempts: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.archived = archived
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.copay = copay
            self.priority = priority
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toProxyExceptionView(_ item: ProxyException) -> ProxyExceptionView {
        return ProxyExceptionView(
            code: item.code,
            label: item.label,
            minimum: String(format: "%.2f", item.minimum),
            archived: "\(item.archived)",
            durationMinutes: String(item.durationMinutes),
            expiresAt: String(item.expiresAt),
            copay: String(format: "%.2f", item.copay),
            priority: String(item.priority),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyExceptionViews(_ items: [ProxyException]) -> [ProxyExceptionView] {
        var views: [ProxyExceptionView] = []
        for item in items {
            views.append(toProxyExceptionView(item))
        }
        return views
    }

    static func sumProxyExceptionView(_ view: ProxyExceptionView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedMinimum + Double(parsedDurationMinutes) + Double(parsedExpiresAt)
    }
}
