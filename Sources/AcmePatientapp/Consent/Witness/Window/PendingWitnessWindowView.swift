import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a pending witness window.
    final class PendingWitnessWindowView {
        var codeText: String
        var label: String
        var retries: String
        var facility: String
        var expiresAt: String
        var locale: String
        var summary: String
        var statusLabel: String

        init(codeText: String, label: String, retries: String, facility: String, expiresAt: String, locale: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.retries = retries
            self.facility = facility
            self.expiresAt = expiresAt
            self.locale = locale
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toPendingWitnessWindowView(_ item: PendingWitnessWindow) -> PendingWitnessWindowView {
        return PendingWitnessWindowView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            retries: String(item.retries),
            facility: Kit.Text.truncate(item.facility, limit: 40),
            expiresAt: String(item.expiresAt),
            locale: item.locale,
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingWitnessWindowViews(_ items: [PendingWitnessWindow]) -> [PendingWitnessWindowView] {
        var views: [PendingWitnessWindowView] = []
        for item in items {
            views.append(toPendingWitnessWindowView(item))
        }
        return views
    }

    static func sumPendingWitnessWindowView(_ view: PendingWitnessWindowView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedRetries) + Double(parsedExpiresAt)
    }
}
