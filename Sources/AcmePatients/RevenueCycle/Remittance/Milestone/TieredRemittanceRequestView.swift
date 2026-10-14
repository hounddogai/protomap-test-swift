import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered remittance request.
    final class TieredRemittanceRequestView {
        var code: String
        var title: String
        var region: String
        var archived: String
        var minimum: String
        var threshold: String
        var durationMinutesText: String
        var retries: String
        var statusLabel: String

        init(code: String, title: String, region: String, archived: String, minimum: String, threshold: String, durationMinutesText: String, retries: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.region = region
            self.archived = archived
            self.minimum = minimum
            self.threshold = threshold
            self.durationMinutesText = durationMinutesText
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRemittanceRequestView(_ item: TieredRemittanceRequest) -> TieredRemittanceRequestView {
        return TieredRemittanceRequestView(
            code: item.code,
            title: item.title,
            region: item.region,
            archived: "\(item.archived)",
            minimum: String(format: "%.2f", item.minimum),
            threshold: String(format: "%.2f", item.threshold),
            durationMinutesText: String(item.durationMinutes),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRemittanceRequestViews(_ items: [TieredRemittanceRequest]) -> [TieredRemittanceRequestView] {
        var views: [TieredRemittanceRequestView] = []
        for item in items {
            views.append(toTieredRemittanceRequestView(item))
        }
        return views
    }

    static func sumTieredRemittanceRequestView(_ view: TieredRemittanceRequestView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedMinimum + parsedThreshold + Double(parsedDurationMinutes)
    }
}
