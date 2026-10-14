import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary witness override.
    final class PrimaryWitnessOverrideView {
        var code: String
        var title: String
        var reviewerText: String
        var specialty: String
        var unit: String
        var durationMinutesText: String
        var ownerID: String
        var maximum: String
        var createdAtText: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, title: String, reviewerText: String, specialty: String, unit: String, durationMinutesText: String, ownerID: String, maximum: String, createdAtText: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.reviewerText = reviewerText
            self.specialty = specialty
            self.unit = unit
            self.durationMinutesText = durationMinutesText
            self.ownerID = ownerID
            self.maximum = maximum
            self.createdAtText = createdAtText
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryWitnessOverrideView(_ item: PrimaryWitnessOverride) -> PrimaryWitnessOverrideView {
        return PrimaryWitnessOverrideView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 64),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 64),
            specialty: item.specialty,
            unit: Kit.Text.truncate(item.unit, limit: 64),
            durationMinutesText: String(item.durationMinutes),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            maximum: String(format: "%.2f", item.maximum),
            createdAtText: String(item.createdAt),
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryWitnessOverrideViews(_ items: [PrimaryWitnessOverride]) -> [PrimaryWitnessOverrideView] {
        var views: [PrimaryWitnessOverrideView] = []
        for item in items {
            views.append(toPrimaryWitnessOverrideView(item))
        }
        return views
    }

    static func sumPrimaryWitnessOverrideView(_ view: PrimaryWitnessOverrideView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedDurationMinutes) + parsedMaximum + Double(parsedCreatedAt)
    }
}
