import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling witness review.
    final class RollingWitnessReviewView {
        var code: String
        var name: String
        var durationMinutes: String
        var active: String
        var capacityText: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, name: String, durationMinutes: String, active: String, capacityText: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.active = active
            self.capacityText = capacityText
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toRollingWitnessReviewView(_ item: RollingWitnessReview) -> RollingWitnessReviewView {
        return RollingWitnessReviewView(
            code: item.code,
            name: item.name,
            durationMinutes: String(item.durationMinutes),
            active: "\(item.active)",
            capacityText: String(item.capacity),
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingWitnessReviewViews(_ items: [RollingWitnessReview]) -> [RollingWitnessReviewView] {
        var views: [RollingWitnessReviewView] = []
        for item in items {
            views.append(toRollingWitnessReviewView(item))
        }
        return views
    }

    static func sumRollingWitnessReviewView(_ view: RollingWitnessReviewView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedCapacity)
    }
}
