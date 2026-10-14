import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a strict follow up audit.
    final class StrictFollowUpAuditView {
        var codeText: String
        var title: String
        var diagnosisCodeText: String
        var floorValue: String
        var name: String
        var reviewerText: String
        var cost: String
        var ward: String
        var locale: String
        var margin: String
        var maximumText: String
        var statusLabel: String

        init(codeText: String, title: String, diagnosisCodeText: String, floorValue: String, name: String, reviewerText: String, cost: String, ward: String, locale: String, margin: String, maximumText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.diagnosisCodeText = diagnosisCodeText
            self.floorValue = floorValue
            self.name = name
            self.reviewerText = reviewerText
            self.cost = cost
            self.ward = ward
            self.locale = locale
            self.margin = margin
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictFollowUpAuditView(_ item: StrictFollowUpAudit) -> StrictFollowUpAuditView {
        return StrictFollowUpAuditView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            diagnosisCodeText: item.diagnosisCode,
            floorValue: String(format: "%.2f", item.floorValue),
            name: Kit.Text.truncate(item.name, limit: 64),
            reviewerText: item.reviewer,
            cost: String(format: "%.2f", item.cost),
            ward: item.ward,
            locale: item.locale,
            margin: String(format: "%.2f", item.margin),
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictFollowUpAuditViews(_ items: [StrictFollowUpAudit]) -> [StrictFollowUpAuditView] {
        var views: [StrictFollowUpAuditView] = []
        for item in items {
            views.append(toStrictFollowUpAuditView(item))
        }
        return views
    }

    static func sumStrictFollowUpAuditView(_ view: StrictFollowUpAuditView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedFloorValue + parsedCost + parsedMargin
    }
}
