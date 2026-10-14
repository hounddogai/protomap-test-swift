import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional accession checkpoint.
    final class RegionalAccessionCheckpointView {
        var code: String
        var name: String
        var encounterID: String
        var titleText: String
        var specialtyText: String
        var summary: String
        var ownerID: String
        var priority: String
        var acuityText: String
        var durationMinutesText: String
        var attemptsText: String
        var statusLabel: String

        init(code: String, name: String, encounterID: String, titleText: String, specialtyText: String, summary: String, ownerID: String, priority: String, acuityText: String, durationMinutesText: String, attemptsText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.titleText = titleText
            self.specialtyText = specialtyText
            self.summary = summary
            self.ownerID = ownerID
            self.priority = priority
            self.acuityText = acuityText
            self.durationMinutesText = durationMinutesText
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalAccessionCheckpointView(_ item: RegionalAccessionCheckpoint) -> RegionalAccessionCheckpointView {
        return RegionalAccessionCheckpointView(
            code: item.code,
            name: item.name,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            titleText: item.title,
            specialtyText: Kit.Text.truncate(item.specialty, limit: 80),
            summary: Kit.Text.truncate(item.summary, limit: 120),
            ownerID: item.ownerID,
            priority: String(item.priority),
            acuityText: String(item.acuity),
            durationMinutesText: String(item.durationMinutes),
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalAccessionCheckpointViews(_ items: [RegionalAccessionCheckpoint]) -> [RegionalAccessionCheckpointView] {
        var views: [RegionalAccessionCheckpointView] = []
        for item in items {
            views.append(toRegionalAccessionCheckpointView(item))
        }
        return views
    }

    static func sumRegionalAccessionCheckpointView(_ view: RegionalAccessionCheckpointView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedPriority) + Double(parsedAcuity) + Double(parsedDurationMinutes)
    }
}
