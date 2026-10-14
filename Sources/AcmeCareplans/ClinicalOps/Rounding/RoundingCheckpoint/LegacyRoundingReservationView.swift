import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a legacy rounding reservation.
    final class LegacyRoundingReservationView {
        var code: String
        var title: String
        var retriesText: String
        var createdAt: String
        var attempts: String
        var dosageMg: String
        var minimum: String
        var label: String
        var statusLabel: String

        init(code: String, title: String, retriesText: String, createdAt: String, attempts: String, dosageMg: String, minimum: String, label: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.retriesText = retriesText
            self.createdAt = createdAt
            self.attempts = attempts
            self.dosageMg = dosageMg
            self.minimum = minimum
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyRoundingReservationView(_ item: LegacyRoundingReservation) -> LegacyRoundingReservationView {
        return LegacyRoundingReservationView(
            code: item.code,
            title: item.title,
            retriesText: String(item.retries),
            createdAt: String(item.createdAt),
            attempts: String(item.attempts),
            dosageMg: String(format: "%.2f", item.dosageMg),
            minimum: String(format: "%.2f", item.minimum),
            label: Kit.Text.truncate(item.label, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyRoundingReservationViews(_ items: [LegacyRoundingReservation]) -> [LegacyRoundingReservationView] {
        var views: [LegacyRoundingReservationView] = []
        for item in items {
            views.append(toLegacyRoundingReservationView(item))
        }
        return views
    }

    static func sumLegacyRoundingReservationView(_ view: LegacyRoundingReservationView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedRetries) + Double(parsedCreatedAt) + Double(parsedAttempts)
    }
}
