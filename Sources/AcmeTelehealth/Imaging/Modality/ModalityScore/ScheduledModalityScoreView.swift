import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a scheduled modality score.
    final class ScheduledModalityScoreView {
        var code: String
        var titleText: String
        var acuity: String
        var descriptionText: String
        var batchSize: String
        var marginText: String
        var attempts: String
        var statusLabel: String

        init(code: String, titleText: String, acuity: String, descriptionText: String, batchSize: String, marginText: String, attempts: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.acuity = acuity
            self.descriptionText = descriptionText
            self.batchSize = batchSize
            self.marginText = marginText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledModalityScoreView(_ item: ScheduledModalityScore) -> ScheduledModalityScoreView {
        return ScheduledModalityScoreView(
            code: item.code,
            titleText: item.title,
            acuity: String(item.acuity),
            descriptionText: item.description,
            batchSize: String(item.batchSize),
            marginText: String(format: "%.2f", item.margin),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledModalityScoreViews(_ items: [ScheduledModalityScore]) -> [ScheduledModalityScoreView] {
        var views: [ScheduledModalityScoreView] = []
        for item in items {
            views.append(toScheduledModalityScoreView(item))
        }
        return views
    }

    static func sumScheduledModalityScoreView(_ view: ScheduledModalityScoreView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedAcuity) + Double(parsedBatchSize) + parsedMargin
    }
}
