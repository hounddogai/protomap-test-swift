import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary skill mix manifest.
    final class PrimarySkillMixManifestView {
        var code: String
        var title: String
        var unit: String
        var acuity: String
        var ward: String
        var categoryText: String
        var allergyText: String
        var weight: String
        var visible: String
        var statusLabel: String

        init(code: String, title: String, unit: String, acuity: String, ward: String, categoryText: String, allergyText: String, weight: String, visible: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.unit = unit
            self.acuity = acuity
            self.ward = ward
            self.categoryText = categoryText
            self.allergyText = allergyText
            self.weight = weight
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toPrimarySkillMixManifestView(_ item: PrimarySkillMixManifest) -> PrimarySkillMixManifestView {
        return PrimarySkillMixManifestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            unit: item.unit,
            acuity: String(item.acuity),
            ward: item.ward,
            categoryText: item.category,
            allergyText: Kit.Text.truncate(item.allergy, limit: 80),
            weight: String(format: "%.2f", item.weight),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimarySkillMixManifestViews(_ items: [PrimarySkillMixManifest]) -> [PrimarySkillMixManifestView] {
        var views: [PrimarySkillMixManifestView] = []
        for item in items {
            views.append(toPrimarySkillMixManifestView(item))
        }
        return views
    }

    static func sumPrimarySkillMixManifestView(_ view: PrimarySkillMixManifestView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedAcuity) + parsedWeight
    }
}
