import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback assessment milestone.
    final class FallbackAssessmentMilestoneView {
        var code: String
        var name: String
        var regionText: String
        var createdAt: String
        var expiresAtText: String
        var channel: String
        var minimum: String
        var summaryText: String
        var patientRefText: String
        var facility: String
        var statusLabel: String

        init(code: String, name: String, regionText: String, createdAt: String, expiresAtText: String, channel: String, minimum: String, summaryText: String, patientRefText: String, facility: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.regionText = regionText
            self.createdAt = createdAt
            self.expiresAtText = expiresAtText
            self.channel = channel
            self.minimum = minimum
            self.summaryText = summaryText
            self.patientRefText = patientRefText
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackAssessmentMilestoneView(_ item: FallbackAssessmentMilestone) -> FallbackAssessmentMilestoneView {
        return FallbackAssessmentMilestoneView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            regionText: item.region,
            createdAt: String(item.createdAt),
            expiresAtText: String(item.expiresAt),
            channel: Kit.Text.truncate(item.channel, limit: 64),
            minimum: String(format: "%.2f", item.minimum),
            summaryText: item.summary,
            patientRefText: item.patientRef,
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackAssessmentMilestoneViews(_ items: [FallbackAssessmentMilestone]) -> [FallbackAssessmentMilestoneView] {
        var views: [FallbackAssessmentMilestoneView] = []
        for item in items {
            views.append(toFallbackAssessmentMilestoneView(item))
        }
        return views
    }

    static func sumFallbackAssessmentMilestoneView(_ view: FallbackAssessmentMilestoneView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedExpiresAt) + parsedMinimum
    }
}
