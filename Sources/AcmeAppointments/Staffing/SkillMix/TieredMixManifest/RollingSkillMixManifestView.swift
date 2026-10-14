import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a rolling skill mix manifest.
    final class RollingSkillMixManifestView {
        var code: String
        var name: String
        var limit: String
        var sequence: String
        var minimum: String
        var bed: String
        var ward: String
        var statusLabel: String

        init(code: String, name: String, limit: String, sequence: String, minimum: String, bed: String, ward: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limit = limit
            self.sequence = sequence
            self.minimum = minimum
            self.bed = bed
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toRollingSkillMixManifestView(_ item: RollingSkillMixManifest) -> RollingSkillMixManifestView {
        return RollingSkillMixManifestView(
            code: item.code,
            name: item.name,
            limit: String(item.limit),
            sequence: String(item.sequence),
            minimum: String(format: "%.2f", item.minimum),
            bed: item.bed,
            ward: Kit.Text.truncate(item.ward, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingSkillMixManifestViews(_ items: [RollingSkillMixManifest]) -> [RollingSkillMixManifestView] {
        var views: [RollingSkillMixManifestView] = []
        for item in items {
            views.append(toRollingSkillMixManifestView(item))
        }
        return views
    }

    static func sumRollingSkillMixManifestView(_ view: RollingSkillMixManifestView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedLimit) + Double(parsedSequence) + parsedMinimum
    }
}
