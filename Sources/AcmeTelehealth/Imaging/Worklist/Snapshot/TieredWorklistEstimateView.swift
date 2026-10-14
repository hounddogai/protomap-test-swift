import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered worklist estimate.
    final class TieredWorklistEstimateView {
        var code: String
        var title: String
        var phone: String
        var patientRef: String
        var windowDays: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, title: String, phone: String, patientRef: String, windowDays: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.phone = phone
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredWorklistEstimateView(_ item: TieredWorklistEstimate) -> TieredWorklistEstimateView {
        return TieredWorklistEstimateView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            phone: Kit.Text.truncate(item.phone, limit: 120),
            patientRef: item.patientRef,
            windowDays: String(item.windowDays),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredWorklistEstimateViews(_ items: [TieredWorklistEstimate]) -> [TieredWorklistEstimateView] {
        var views: [TieredWorklistEstimateView] = []
        for item in items {
            views.append(toTieredWorklistEstimateView(item))
        }
        return views
    }

    static func sumTieredWorklistEstimateView(_ view: TieredWorklistEstimateView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedDurationMinutes)
    }
}
