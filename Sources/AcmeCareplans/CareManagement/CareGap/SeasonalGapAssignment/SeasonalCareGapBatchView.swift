import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal care gap batch.
    final class SeasonalCareGapBatchView {
        var code: String
        var title: String
        var contactEmailText: String
        var timezone: String
        var retries: String
        var approved: String
        var statusLabel: String

        init(code: String, title: String, contactEmailText: String, timezone: String, retries: String, approved: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.contactEmailText = contactEmailText
            self.timezone = timezone
            self.retries = retries
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCareGapBatchView(_ item: SeasonalCareGapBatch) -> SeasonalCareGapBatchView {
        return SeasonalCareGapBatchView(
            code: item.code,
            title: item.title,
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 64),
            timezone: item.timezone,
            retries: String(item.retries),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCareGapBatchViews(_ items: [SeasonalCareGapBatch]) -> [SeasonalCareGapBatchView] {
        var views: [SeasonalCareGapBatchView] = []
        for item in items {
            views.append(toSeasonalCareGapBatchView(item))
        }
        return views
    }

    static func sumSeasonalCareGapBatchView(_ view: SeasonalCareGapBatchView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRetries)
    }
}
