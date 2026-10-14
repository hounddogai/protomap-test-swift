import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a regional risk score variance.
    final class RegionalRiskScoreVarianceView {
        var code: String
        var titleText: String
        var contactEmail: String
        var rate: String
        var facility: String
        var approved: String
        var marginText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, titleText: String, contactEmail: String, rate: String, facility: String, approved: String, marginText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.contactEmail = contactEmail
            self.rate = rate
            self.facility = facility
            self.approved = approved
            self.marginText = marginText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRiskScoreVarianceView(_ item: RegionalRiskScoreVariance) -> RegionalRiskScoreVarianceView {
        return RegionalRiskScoreVarianceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            contactEmail: item.contactEmail,
            rate: String(format: "%.2f", item.rate),
            facility: Kit.Text.truncate(item.facility, limit: 120),
            approved: "\(item.approved)",
            marginText: String(format: "%.2f", item.margin),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRiskScoreVarianceViews(_ items: [RegionalRiskScoreVariance]) -> [RegionalRiskScoreVarianceView] {
        var views: [RegionalRiskScoreVarianceView] = []
        for item in items {
            views.append(toRegionalRiskScoreVarianceView(item))
        }
        return views
    }

    static func sumRegionalRiskScoreVarianceView(_ view: RegionalRiskScoreVarianceView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedRate + parsedMargin + parsedFloorValue
    }
}
