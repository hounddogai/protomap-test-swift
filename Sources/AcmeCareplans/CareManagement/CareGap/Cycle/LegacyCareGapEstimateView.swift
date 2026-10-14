import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a legacy care gap estimate.
    final class LegacyCareGapEstimateView {
        var codeText: String
        var name: String
        var clinicianID: String
        var visitMinutesText: String
        var encounterID: String
        var facility: String
        var startsAt: String
        var durationMinutes: String
        var ratio: String
        var statusLabel: String

        init(codeText: String, name: String, clinicianID: String, visitMinutesText: String, encounterID: String, facility: String, startsAt: String, durationMinutes: String, ratio: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.clinicianID = clinicianID
            self.visitMinutesText = visitMinutesText
            self.encounterID = encounterID
            self.facility = facility
            self.startsAt = startsAt
            self.durationMinutes = durationMinutes
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCareGapEstimateView(_ item: LegacyCareGapEstimate) -> LegacyCareGapEstimateView {
        return LegacyCareGapEstimateView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 120),
            clinicianID: item.clinicianID,
            visitMinutesText: String(item.visitMinutes),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            facility: item.facility,
            startsAt: String(item.startsAt),
            durationMinutes: String(item.durationMinutes),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCareGapEstimateViews(_ items: [LegacyCareGapEstimate]) -> [LegacyCareGapEstimateView] {
        var views: [LegacyCareGapEstimateView] = []
        for item in items {
            views.append(toLegacyCareGapEstimateView(item))
        }
        return views
    }

    static func sumLegacyCareGapEstimateView(_ view: LegacyCareGapEstimateView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedStartsAt) + Double(parsedDurationMinutes)
    }
}
