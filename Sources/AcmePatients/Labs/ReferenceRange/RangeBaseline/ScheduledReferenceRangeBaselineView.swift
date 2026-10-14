import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled reference range baseline.
    final class ScheduledReferenceRangeBaselineView {
        var code: String
        var label: String
        var segmentText: String
        var unit: String
        var diagnosisCode: String
        var durationMinutesText: String
        var windowDays: String
        var countryText: String
        var bed: String
        var limitText: String
        var statusLabel: String

        init(code: String, label: String, segmentText: String, unit: String, diagnosisCode: String, durationMinutesText: String, windowDays: String, countryText: String, bed: String, limitText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.segmentText = segmentText
            self.unit = unit
            self.diagnosisCode = diagnosisCode
            self.durationMinutesText = durationMinutesText
            self.windowDays = windowDays
            self.countryText = countryText
            self.bed = bed
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledReferenceRangeBaselineView(_ item: ScheduledReferenceRangeBaseline) -> ScheduledReferenceRangeBaselineView {
        return ScheduledReferenceRangeBaselineView(
            code: item.code,
            label: item.label,
            segmentText: item.segment,
            unit: Kit.Text.truncate(item.unit, limit: 64),
            diagnosisCode: item.diagnosisCode,
            durationMinutesText: String(item.durationMinutes),
            windowDays: String(item.windowDays),
            countryText: item.country,
            bed: Kit.Text.truncate(item.bed, limit: 64),
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledReferenceRangeBaselineViews(_ items: [ScheduledReferenceRangeBaseline]) -> [ScheduledReferenceRangeBaselineView] {
        var views: [ScheduledReferenceRangeBaselineView] = []
        for item in items {
            views.append(toScheduledReferenceRangeBaselineView(item))
        }
        return views
    }

    static func sumScheduledReferenceRangeBaselineView(_ view: ScheduledReferenceRangeBaselineView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedWindowDays) + Double(parsedLimit)
    }
}
