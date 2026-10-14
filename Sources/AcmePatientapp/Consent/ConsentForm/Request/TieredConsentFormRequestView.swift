import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a tiered consent form request.
    final class TieredConsentFormRequestView {
        var code: String
        var labelText: String
        var windowDaysText: String
        var batchSize: String
        var regionText: String
        var locale: String
        var graceDays: String
        var visitMinutesText: String
        var category: String
        var active: String
        var statusLabel: String

        init(code: String, labelText: String, windowDaysText: String, batchSize: String, regionText: String, locale: String, graceDays: String, visitMinutesText: String, category: String, active: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.windowDaysText = windowDaysText
            self.batchSize = batchSize
            self.regionText = regionText
            self.locale = locale
            self.graceDays = graceDays
            self.visitMinutesText = visitMinutesText
            self.category = category
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toTieredConsentFormRequestView(_ item: TieredConsentFormRequest) -> TieredConsentFormRequestView {
        return TieredConsentFormRequestView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            windowDaysText: String(item.windowDays),
            batchSize: String(item.batchSize),
            regionText: Kit.Text.truncate(item.region, limit: 40),
            locale: item.locale,
            graceDays: String(item.graceDays),
            visitMinutesText: String(item.visitMinutes),
            category: item.category,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredConsentFormRequestViews(_ items: [TieredConsentFormRequest]) -> [TieredConsentFormRequestView] {
        var views: [TieredConsentFormRequestView] = []
        for item in items {
            views.append(toTieredConsentFormRequestView(item))
        }
        return views
    }

    static func sumTieredConsentFormRequestView(_ view: TieredConsentFormRequestView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedBatchSize) + Double(parsedGraceDays)
    }
}
