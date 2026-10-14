import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional consent form target.
    final class RegionalConsentFormTargetView {
        var codeText: String
        var titleText: String
        var weight: String
        var category: String
        var unit: String
        var priorityText: String
        var statusLabel: String

        init(codeText: String, titleText: String, weight: String, category: String, unit: String, priorityText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.weight = weight
            self.category = category
            self.unit = unit
            self.priorityText = priorityText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalConsentFormTargetView(_ item: RegionalConsentFormTarget) -> RegionalConsentFormTargetView {
        return RegionalConsentFormTargetView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            weight: String(format: "%.2f", item.weight),
            category: item.category,
            unit: item.unit,
            priorityText: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalConsentFormTargetViews(_ items: [RegionalConsentFormTarget]) -> [RegionalConsentFormTargetView] {
        var views: [RegionalConsentFormTargetView] = []
        for item in items {
            views.append(toRegionalConsentFormTargetView(item))
        }
        return views
    }

    static func sumRegionalConsentFormTargetView(_ view: RegionalConsentFormTargetView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedWeight + Double(parsedPriority)
    }
}
