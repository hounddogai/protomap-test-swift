import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional charge entry.
    final class RegionalChargeEntryView {
        var code: String
        var labelText: String
        var retries: String
        var visitMinutesText: String
        var payer: String
        var region: String
        var reviewer: String
        var facilityText: String
        var statusLabel: String

        init(code: String, labelText: String, retries: String, visitMinutesText: String, payer: String, region: String, reviewer: String, facilityText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.retries = retries
            self.visitMinutesText = visitMinutesText
            self.payer = payer
            self.region = region
            self.reviewer = reviewer
            self.facilityText = facilityText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalChargeEntryView(_ item: RegionalChargeEntry) -> RegionalChargeEntryView {
        return RegionalChargeEntryView(
            code: item.code,
            labelText: item.label,
            retries: String(item.retries),
            visitMinutesText: String(item.visitMinutes),
            payer: Kit.Text.truncate(item.payer, limit: 40),
            region: Kit.Text.truncate(item.region, limit: 120),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            facilityText: Kit.Text.truncate(item.facility, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalChargeEntryViews(_ items: [RegionalChargeEntry]) -> [RegionalChargeEntryView] {
        var views: [RegionalChargeEntryView] = []
        for item in items {
            views.append(toRegionalChargeEntryView(item))
        }
        return views
    }

    static func sumRegionalChargeEntryView(_ view: RegionalChargeEntryView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedRetries) + Double(parsedVisitMinutes)
    }
}
