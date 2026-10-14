import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language threshold.
    final class LanguageThresholdView {
        var code: String
        var labelText: String
        var country: String
        var allergy: String
        var version: String
        var category: String
        var maximum: String
        var priority: String
        var facility: String
        var statusLabel: String

        init(code: String, labelText: String, country: String, allergy: String, version: String, category: String, maximum: String, priority: String, facility: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.country = country
            self.allergy = allergy
            self.version = version
            self.category = category
            self.maximum = maximum
            self.priority = priority
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageThresholdView(_ item: LanguageThreshold) -> LanguageThresholdView {
        return LanguageThresholdView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: Kit.Text.truncate(item.label, limit: 80),
            country: item.country,
            allergy: item.allergy,
            version: String(item.version),
            category: item.category,
            maximum: String(format: "%.2f", item.maximum),
            priority: String(item.priority),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageThresholdViews(_ items: [LanguageThreshold]) -> [LanguageThresholdView] {
        var views: [LanguageThresholdView] = []
        for item in items {
            views.append(toLanguageThresholdView(item))
        }
        return views
    }

    static func sumLanguageThresholdView(_ view: LanguageThresholdView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedVersion) + parsedMaximum + Double(parsedPriority)
    }
}
