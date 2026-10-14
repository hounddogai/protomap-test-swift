import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a fallback witness draft.
    final class FallbackWitnessDraftView {
        var code: String
        var title: String
        var description: String
        var durationMinutes: String
        var externalRef: String
        var startsAt: String
        var thresholdText: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, title: String, description: String, durationMinutes: String, externalRef: String, startsAt: String, thresholdText: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.durationMinutes = durationMinutes
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.thresholdText = thresholdText
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackWitnessDraftView(_ item: FallbackWitnessDraft) -> FallbackWitnessDraftView {
        return FallbackWitnessDraftView(
            code: item.code,
            title: item.title,
            description: item.description,
            durationMinutes: String(item.durationMinutes),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            startsAt: String(item.startsAt),
            thresholdText: String(format: "%.2f", item.threshold),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackWitnessDraftViews(_ items: [FallbackWitnessDraft]) -> [FallbackWitnessDraftView] {
        var views: [FallbackWitnessDraftView] = []
        for item in items {
            views.append(toFallbackWitnessDraftView(item))
        }
        return views
    }

    static func sumFallbackWitnessDraftView(_ view: FallbackWitnessDraftView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedStartsAt) + parsedThreshold
    }
}
