import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix request.
    final class SkillMixRequestView {
        var code: String
        var name: String
        var ward: String
        var archivedText: String
        var category: String
        var ceiling: String
        var maximumText: String
        var statusLabel: String

        init(code: String, name: String, ward: String, archivedText: String, category: String, ceiling: String, maximumText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ward = ward
            self.archivedText = archivedText
            self.category = category
            self.ceiling = ceiling
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixRequestView(_ item: SkillMixRequest) -> SkillMixRequestView {
        return SkillMixRequestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            ward: item.ward,
            archivedText: "\(item.archived)",
            category: item.category,
            ceiling: String(format: "%.2f", item.ceiling),
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixRequestViews(_ items: [SkillMixRequest]) -> [SkillMixRequestView] {
        var views: [SkillMixRequestView] = []
        for item in items {
            views.append(toSkillMixRequestView(item))
        }
        return views
    }

    static func sumSkillMixRequestView(_ view: SkillMixRequestView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCeiling + parsedMaximum
    }
}
