import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score estimate.
    final class RiskScoreEstimateView {
        var code: String
        var title: String
        var notes: String
        var approvedText: String
        var ownerIDText: String
        var marginText: String
        var revisionText: String
        var durationMinutes: String
        var facilityText: String
        var windowDaysText: String
        var timezone: String
        var statusLabel: String

        init(code: String, title: String, notes: String, approvedText: String, ownerIDText: String, marginText: String, revisionText: String, durationMinutes: String, facilityText: String, windowDaysText: String, timezone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.notes = notes
            self.approvedText = approvedText
            self.ownerIDText = ownerIDText
            self.marginText = marginText
            self.revisionText = revisionText
            self.durationMinutes = durationMinutes
            self.facilityText = facilityText
            self.windowDaysText = windowDaysText
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreEstimateView(_ item: RiskScoreEstimate) -> RiskScoreEstimateView {
        return RiskScoreEstimateView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            notes: item.notes,
            approvedText: "\(item.approved)",
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 80),
            marginText: String(format: "%.2f", item.margin),
            revisionText: String(item.revision),
            durationMinutes: String(item.durationMinutes),
            facilityText: item.facility,
            windowDaysText: String(item.windowDays),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreEstimateViews(_ items: [RiskScoreEstimate]) -> [RiskScoreEstimateView] {
        var views: [RiskScoreEstimateView] = []
        for item in items {
            views.append(toRiskScoreEstimateView(item))
        }
        return views
    }

    static func sumRiskScoreEstimateView(_ view: RiskScoreEstimateView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedMargin + Double(parsedRevision) + Double(parsedDurationMinutes)
    }
}
