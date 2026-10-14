import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a weighted courier override.
    final class WeightedCourierOverrideView {
        var code: String
        var labelText: String
        var limit: String
        var name: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, labelText: String, limit: String, name: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.limit = limit
            self.name = name
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedCourierOverrideView(_ item: WeightedCourierOverride) -> WeightedCourierOverrideView {
        return WeightedCourierOverrideView(
            code: item.code,
            labelText: item.label,
            limit: String(item.limit),
            name: item.name,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedCourierOverrideViews(_ items: [WeightedCourierOverride]) -> [WeightedCourierOverrideView] {
        var views: [WeightedCourierOverrideView] = []
        for item in items {
            views.append(toWeightedCourierOverrideView(item))
        }
        return views
    }

    static func sumWeightedCourierOverrideView(_ view: WeightedCourierOverrideView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
