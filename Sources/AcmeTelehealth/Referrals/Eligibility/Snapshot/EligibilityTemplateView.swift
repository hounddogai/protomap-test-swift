import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility template.
    final class EligibilityTemplateView {
        var code: String
        var label: String
        var visitMinutes: String
        var pinned: String
        var floorValueText: String
        var summaryText: String
        var statusLabel: String

        init(code: String, label: String, visitMinutes: String, pinned: String, floorValueText: String, summaryText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.pinned = pinned
            self.floorValueText = floorValueText
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityTemplateView(_ item: EligibilityTemplate) -> EligibilityTemplateView {
        return EligibilityTemplateView(
            code: item.code,
            label: item.label,
            visitMinutes: String(item.visitMinutes),
            pinned: "\(item.pinned)",
            floorValueText: String(format: "%.2f", item.floorValue),
            summaryText: Kit.Text.truncate(item.summary, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityTemplateViews(_ items: [EligibilityTemplate]) -> [EligibilityTemplateView] {
        var views: [EligibilityTemplateView] = []
        for item in items {
            views.append(toEligibilityTemplateView(item))
        }
        return views
    }

    static func sumEligibilityTemplateView(_ view: EligibilityTemplateView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedVisitMinutes) + parsedFloorValue
    }
}
