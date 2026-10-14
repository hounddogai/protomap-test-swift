import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict modality target.
    final class StrictModalityTargetView {
        var code: String
        var label: String
        var timezoneText: String
        var updatedAt: String
        var categoryText: String
        var statusLabel: String

        init(code: String, label: String, timezoneText: String, updatedAt: String, categoryText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.timezoneText = timezoneText
            self.updatedAt = updatedAt
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictModalityTargetView(_ item: StrictModalityTarget) -> StrictModalityTargetView {
        return StrictModalityTargetView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            timezoneText: item.timezone,
            updatedAt: String(item.updatedAt),
            categoryText: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictModalityTargetViews(_ items: [StrictModalityTarget]) -> [StrictModalityTargetView] {
        var views: [StrictModalityTargetView] = []
        for item in items {
            views.append(toStrictModalityTargetView(item))
        }
        return views
    }

    static func sumStrictModalityTargetView(_ view: StrictModalityTargetView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
