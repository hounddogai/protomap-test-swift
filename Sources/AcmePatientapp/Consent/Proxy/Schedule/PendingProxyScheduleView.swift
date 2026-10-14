import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a pending proxy schedule.
    final class PendingProxyScheduleView {
        var code: String
        var titleText: String
        var currency: String
        var durationMinutesText: String
        var ward: String
        var createdAtText: String
        var clinicianIDText: String
        var score: String
        var externalRefText: String
        var statusLabel: String

        init(code: String, titleText: String, currency: String, durationMinutesText: String, ward: String, createdAtText: String, clinicianIDText: String, score: String, externalRefText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.currency = currency
            self.durationMinutesText = durationMinutesText
            self.ward = ward
            self.createdAtText = createdAtText
            self.clinicianIDText = clinicianIDText
            self.score = score
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingProxyScheduleView(_ item: PendingProxySchedule) -> PendingProxyScheduleView {
        return PendingProxyScheduleView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            currency: item.currency,
            durationMinutesText: String(item.durationMinutes),
            ward: item.ward,
            createdAtText: String(item.createdAt),
            clinicianIDText: item.clinicianID,
            score: String(format: "%.2f", item.score),
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingProxyScheduleViews(_ items: [PendingProxySchedule]) -> [PendingProxyScheduleView] {
        var views: [PendingProxyScheduleView] = []
        for item in items {
            views.append(toPendingProxyScheduleView(item))
        }
        return views
    }

    static func sumPendingProxyScheduleView(_ view: PendingProxyScheduleView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedCreatedAt) + parsedScore
    }
}
