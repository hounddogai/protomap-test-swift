import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rolling alert review.
    final class RollingAlertReviewView {
        var code: String
        var name: String
        var costText: String
        var weight: String
        var approved: String
        var reviewer: String
        var floorValue: String
        var locale: String
        var amountText: String
        var statusLabel: String

        init(code: String, name: String, costText: String, weight: String, approved: String, reviewer: String, floorValue: String, locale: String, amountText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.costText = costText
            self.weight = weight
            self.approved = approved
            self.reviewer = reviewer
            self.floorValue = floorValue
            self.locale = locale
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAlertReviewView(_ item: RollingAlertReview) -> RollingAlertReviewView {
        return RollingAlertReviewView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            costText: String(format: "%.2f", item.cost),
            weight: String(format: "%.2f", item.weight),
            approved: "\(item.approved)",
            reviewer: item.reviewer,
            floorValue: String(format: "%.2f", item.floorValue),
            locale: item.locale,
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAlertReviewViews(_ items: [RollingAlertReview]) -> [RollingAlertReviewView] {
        var views: [RollingAlertReviewView] = []
        for item in items {
            views.append(toRollingAlertReviewView(item))
        }
        return views
    }

    static func sumRollingAlertReviewView(_ view: RollingAlertReviewView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedCost + parsedWeight + parsedFloorValue
    }
}
