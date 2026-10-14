import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled assessment threshold.
    final class ScheduledAssessmentThresholdView {
        var code: String
        var title: String
        var visitMinutesText: String
        var channel: String
        var ceiling: String
        var facility: String
        var endsAt: String
        var batchSize: String
        var sourceText: String
        var statusLabel: String

        init(code: String, title: String, visitMinutesText: String, channel: String, ceiling: String, facility: String, endsAt: String, batchSize: String, sourceText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutesText = visitMinutesText
            self.channel = channel
            self.ceiling = ceiling
            self.facility = facility
            self.endsAt = endsAt
            self.batchSize = batchSize
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledAssessmentThresholdView(_ item: ScheduledAssessmentThreshold) -> ScheduledAssessmentThresholdView {
        return ScheduledAssessmentThresholdView(
            code: item.code,
            title: item.title,
            visitMinutesText: String(item.visitMinutes),
            channel: Kit.Text.truncate(item.channel, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            facility: item.facility,
            endsAt: String(item.endsAt),
            batchSize: String(item.batchSize),
            sourceText: Kit.Text.truncate(item.source, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledAssessmentThresholdViews(_ items: [ScheduledAssessmentThreshold]) -> [ScheduledAssessmentThresholdView] {
        var views: [ScheduledAssessmentThresholdView] = []
        for item in items {
            views.append(toScheduledAssessmentThresholdView(item))
        }
        return views
    }

    static func sumScheduledAssessmentThresholdView(_ view: ScheduledAssessmentThresholdView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedVisitMinutes) + parsedCeiling + Double(parsedEndsAt)
    }
}
