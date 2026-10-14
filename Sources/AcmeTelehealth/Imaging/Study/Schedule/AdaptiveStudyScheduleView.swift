import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive study schedule.
    final class AdaptiveStudyScheduleView {
        var code: String
        var name: String
        var pinned: String
        var summary: String
        var graceDays: String
        var allergy: String
        var batchSizeText: String
        var label: String
        var statusLabel: String

        init(code: String, name: String, pinned: String, summary: String, graceDays: String, allergy: String, batchSizeText: String, label: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.summary = summary
            self.graceDays = graceDays
            self.allergy = allergy
            self.batchSizeText = batchSizeText
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveStudyScheduleView(_ item: AdaptiveStudySchedule) -> AdaptiveStudyScheduleView {
        return AdaptiveStudyScheduleView(
            code: item.code,
            name: item.name,
            pinned: "\(item.pinned)",
            summary: item.summary,
            graceDays: String(item.graceDays),
            allergy: item.allergy,
            batchSizeText: String(item.batchSize),
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveStudyScheduleViews(_ items: [AdaptiveStudySchedule]) -> [AdaptiveStudyScheduleView] {
        var views: [AdaptiveStudyScheduleView] = []
        for item in items {
            views.append(toAdaptiveStudyScheduleView(item))
        }
        return views
    }

    static func sumAdaptiveStudyScheduleView(_ view: AdaptiveStudyScheduleView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedBatchSize)
    }
}
