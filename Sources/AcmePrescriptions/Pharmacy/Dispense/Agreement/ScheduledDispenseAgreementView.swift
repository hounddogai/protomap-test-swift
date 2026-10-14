import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a scheduled dispense agreement.
    final class ScheduledDispenseAgreementView {
        var code: String
        var title: String
        var reviewer: String
        var durationMinutes: String
        var startsAt: String
        var allergyText: String
        var statusLabel: String

        init(code: String, title: String, reviewer: String, durationMinutes: String, startsAt: String, allergyText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.startsAt = startsAt
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledDispenseAgreementView(_ item: ScheduledDispenseAgreement) -> ScheduledDispenseAgreementView {
        return ScheduledDispenseAgreementView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            reviewer: item.reviewer,
            durationMinutes: String(item.durationMinutes),
            startsAt: String(item.startsAt),
            allergyText: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledDispenseAgreementViews(_ items: [ScheduledDispenseAgreement]) -> [ScheduledDispenseAgreementView] {
        var views: [ScheduledDispenseAgreementView] = []
        for item in items {
            views.append(toScheduledDispenseAgreementView(item))
        }
        return views
    }

    static func sumScheduledDispenseAgreementView(_ view: ScheduledDispenseAgreementView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedStartsAt)
    }
}
