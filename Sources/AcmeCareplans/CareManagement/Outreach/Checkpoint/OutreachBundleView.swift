import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach bundle.
    final class OutreachBundleView {
        var code: String
        var title: String
        var allergyText: String
        var threshold: String
        var description: String
        var windowDays: String
        var statusLabel: String

        init(code: String, title: String, allergyText: String, threshold: String, description: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.allergyText = allergyText
            self.threshold = threshold
            self.description = description
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachBundleView(_ item: OutreachBundle) -> OutreachBundleView {
        return OutreachBundleView(
            code: item.code,
            title: item.title,
            allergyText: item.allergy,
            threshold: String(format: "%.2f", item.threshold),
            description: Kit.Text.truncate(item.description, limit: 64),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachBundleViews(_ items: [OutreachBundle]) -> [OutreachBundleView] {
        var views: [OutreachBundleView] = []
        for item in items {
            views.append(toOutreachBundleView(item))
        }
        return views
    }

    static func sumOutreachBundleView(_ view: OutreachBundleView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedThreshold + Double(parsedWindowDays)
    }
}
