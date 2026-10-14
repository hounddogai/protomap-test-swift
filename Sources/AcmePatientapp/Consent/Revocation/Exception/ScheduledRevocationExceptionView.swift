import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled revocation exception.
    final class ScheduledRevocationExceptionView {
        var codeText: String
        var name: String
        var category: String
        var ceiling: String
        var segment: String
        var allergy: String
        var statusLabel: String

        init(codeText: String, name: String, category: String, ceiling: String, segment: String, allergy: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.category = category
            self.ceiling = ceiling
            self.segment = segment
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledRevocationExceptionView(_ item: ScheduledRevocationException) -> ScheduledRevocationExceptionView {
        return ScheduledRevocationExceptionView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 64),
            category: item.category,
            ceiling: String(format: "%.2f", item.ceiling),
            segment: Kit.Text.truncate(item.segment, limit: 120),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledRevocationExceptionViews(_ items: [ScheduledRevocationException]) -> [ScheduledRevocationExceptionView] {
        var views: [ScheduledRevocationExceptionView] = []
        for item in items {
            views.append(toScheduledRevocationExceptionView(item))
        }
        return views
    }

    static func sumScheduledRevocationExceptionView(_ view: ScheduledRevocationExceptionView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
