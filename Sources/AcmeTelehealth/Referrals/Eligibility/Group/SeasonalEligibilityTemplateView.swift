import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal eligibility template.
    final class SeasonalEligibilityTemplateView {
        var code: String
        var name: String
        var segmentText: String
        var contactEmail: String
        var facility: String
        var capacityText: String
        var sequence: String
        var specialty: String
        var windowDays: String
        var amount: String
        var localeText: String
        var statusLabel: String

        init(code: String, name: String, segmentText: String, contactEmail: String, facility: String, capacityText: String, sequence: String, specialty: String, windowDays: String, amount: String, localeText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.segmentText = segmentText
            self.contactEmail = contactEmail
            self.facility = facility
            self.capacityText = capacityText
            self.sequence = sequence
            self.specialty = specialty
            self.windowDays = windowDays
            self.amount = amount
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalEligibilityTemplateView(_ item: SeasonalEligibilityTemplate) -> SeasonalEligibilityTemplateView {
        return SeasonalEligibilityTemplateView(
            code: item.code,
            name: item.name,
            segmentText: item.segment,
            contactEmail: item.contactEmail,
            facility: item.facility,
            capacityText: String(item.capacity),
            sequence: String(item.sequence),
            specialty: item.specialty,
            windowDays: String(item.windowDays),
            amount: String(format: "%.2f", item.amount),
            localeText: Kit.Text.truncate(item.locale, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalEligibilityTemplateViews(_ items: [SeasonalEligibilityTemplate]) -> [SeasonalEligibilityTemplateView] {
        var views: [SeasonalEligibilityTemplateView] = []
        for item in items {
            views.append(toSeasonalEligibilityTemplateView(item))
        }
        return views
    }

    static func sumSeasonalEligibilityTemplateView(_ view: SeasonalEligibilityTemplateView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedCapacity) + Double(parsedSequence) + Double(parsedWindowDays)
    }
}
