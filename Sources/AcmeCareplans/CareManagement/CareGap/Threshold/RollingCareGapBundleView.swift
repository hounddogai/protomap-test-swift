import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a rolling care gap bundle.
    final class RollingCareGapBundleView {
        var codeText: String
        var titleText: String
        var margin: String
        var localeText: String
        var ratioText: String
        var priority: String
        var name: String
        var statusLabel: String

        init(codeText: String, titleText: String, margin: String, localeText: String, ratioText: String, priority: String, name: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.margin = margin
            self.localeText = localeText
            self.ratioText = ratioText
            self.priority = priority
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCareGapBundleView(_ item: RollingCareGapBundle) -> RollingCareGapBundleView {
        return RollingCareGapBundleView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            margin: String(format: "%.2f", item.margin),
            localeText: item.locale,
            ratioText: String(format: "%.2f", item.ratio),
            priority: String(item.priority),
            name: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCareGapBundleViews(_ items: [RollingCareGapBundle]) -> [RollingCareGapBundleView] {
        var views: [RollingCareGapBundleView] = []
        for item in items {
            views.append(toRollingCareGapBundleView(item))
        }
        return views
    }

    static func sumRollingCareGapBundleView(_ view: RollingCareGapBundleView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedMargin + parsedRatio + Double(parsedPriority)
    }
}
