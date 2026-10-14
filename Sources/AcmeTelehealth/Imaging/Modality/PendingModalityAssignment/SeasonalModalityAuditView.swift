import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal modality audit.
    final class SeasonalModalityAuditView {
        var codeText: String
        var title: String
        var clinicianIDText: String
        var allergy: String
        var maximum: String
        var startsAt: String
        var reviewerText: String
        var attempts: String
        var facility: String
        var amount: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, title: String, clinicianIDText: String, allergy: String, maximum: String, startsAt: String, reviewerText: String, attempts: String, facility: String, amount: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.clinicianIDText = clinicianIDText
            self.allergy = allergy
            self.maximum = maximum
            self.startsAt = startsAt
            self.reviewerText = reviewerText
            self.attempts = attempts
            self.facility = facility
            self.amount = amount
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalModalityAuditView(_ item: SeasonalModalityAudit) -> SeasonalModalityAuditView {
        return SeasonalModalityAuditView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 64),
            allergy: item.allergy,
            maximum: String(format: "%.2f", item.maximum),
            startsAt: String(item.startsAt),
            reviewerText: item.reviewer,
            attempts: String(item.attempts),
            facility: Kit.Text.truncate(item.facility, limit: 40),
            amount: String(format: "%.2f", item.amount),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalModalityAuditViews(_ items: [SeasonalModalityAudit]) -> [SeasonalModalityAuditView] {
        var views: [SeasonalModalityAuditView] = []
        for item in items {
            views.append(toSeasonalModalityAuditView(item))
        }
        return views
    }

    static func sumSeasonalModalityAuditView(_ view: SeasonalModalityAuditView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedMaximum + Double(parsedStartsAt) + Double(parsedAttempts)
    }
}
