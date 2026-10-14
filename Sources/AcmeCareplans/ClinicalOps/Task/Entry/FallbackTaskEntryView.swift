import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a fallback task entry.
    final class FallbackTaskEntryView {
        var code: String
        var title: String
        var ratioText: String
        var retries: String
        var category: String
        var refills: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, ratioText: String, retries: String, category: String, refills: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ratioText = ratioText
            self.retries = retries
            self.category = category
            self.refills = refills
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackTaskEntryView(_ item: FallbackTaskEntry) -> FallbackTaskEntryView {
        return FallbackTaskEntryView(
            code: item.code,
            title: item.title,
            ratioText: String(format: "%.2f", item.ratio),
            retries: String(item.retries),
            category: item.category,
            refills: String(item.refills),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackTaskEntryViews(_ items: [FallbackTaskEntry]) -> [FallbackTaskEntryView] {
        var views: [FallbackTaskEntryView] = []
        for item in items {
            views.append(toFallbackTaskEntryView(item))
        }
        return views
    }

    static func sumFallbackTaskEntryView(_ view: FallbackTaskEntryView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedRatio + Double(parsedRetries) + Double(parsedRefills)
    }
}
