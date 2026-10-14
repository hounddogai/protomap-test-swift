import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study adjustment.
    final class StudyAdjustmentView {
        var code: String
        var title: String
        var pinned: String
        var retriesText: String
        var copay: String
        var visibleText: String
        var source: String
        var margin: String
        var rate: String
        var statusLabel: String

        init(code: String, title: String, pinned: String, retriesText: String, copay: String, visibleText: String, source: String, margin: String, rate: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.retriesText = retriesText
            self.copay = copay
            self.visibleText = visibleText
            self.source = source
            self.margin = margin
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toStudyAdjustmentView(_ item: StudyAdjustment) -> StudyAdjustmentView {
        return StudyAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            pinned: "\(item.pinned)",
            retriesText: String(item.retries),
            copay: String(format: "%.2f", item.copay),
            visibleText: "\(item.visible)",
            source: Kit.Text.truncate(item.source, limit: 80),
            margin: String(format: "%.2f", item.margin),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyAdjustmentViews(_ items: [StudyAdjustment]) -> [StudyAdjustmentView] {
        var views: [StudyAdjustmentView] = []
        for item in items {
            views.append(toStudyAdjustmentView(item))
        }
        return views
    }

    static func sumStudyAdjustmentView(_ view: StudyAdjustmentView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedRetries) + parsedCopay + parsedMargin
    }
}
