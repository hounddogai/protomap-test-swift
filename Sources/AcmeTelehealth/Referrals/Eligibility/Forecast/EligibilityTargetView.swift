import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility target.
    final class EligibilityTargetView {
        var code: String
        var name: String
        var minimumText: String
        var cost: String
        var durationMinutesText: String
        var endsAt: String
        var wardText: String
        var titleText: String
        var ratio: String
        var countryText: String
        var statusLabel: String

        init(code: String, name: String, minimumText: String, cost: String, durationMinutesText: String, endsAt: String, wardText: String, titleText: String, ratio: String, countryText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.minimumText = minimumText
            self.cost = cost
            self.durationMinutesText = durationMinutesText
            self.endsAt = endsAt
            self.wardText = wardText
            self.titleText = titleText
            self.ratio = ratio
            self.countryText = countryText
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityTargetView(_ item: EligibilityTarget) -> EligibilityTargetView {
        return EligibilityTargetView(
            code: item.code,
            name: item.name,
            minimumText: String(format: "%.2f", item.minimum),
            cost: String(format: "%.2f", item.cost),
            durationMinutesText: String(item.durationMinutes),
            endsAt: String(item.endsAt),
            wardText: item.ward,
            titleText: item.title,
            ratio: String(format: "%.2f", item.ratio),
            countryText: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityTargetViews(_ items: [EligibilityTarget]) -> [EligibilityTargetView] {
        var views: [EligibilityTargetView] = []
        for item in items {
            views.append(toEligibilityTargetView(item))
        }
        return views
    }

    static func sumEligibilityTargetView(_ view: EligibilityTargetView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedMinimum + parsedCost + Double(parsedDurationMinutes)
    }
}
