import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix manifest.
    final class SkillMixManifestView {
        var code: String
        var name: String
        var sequenceText: String
        var currency: String
        var threshold: String
        var statusLabel: String

        init(code: String, name: String, sequenceText: String, currency: String, threshold: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.sequenceText = sequenceText
            self.currency = currency
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixManifestView(_ item: SkillMixManifest) -> SkillMixManifestView {
        return SkillMixManifestView(
            code: item.code,
            name: item.name,
            sequenceText: String(item.sequence),
            currency: item.currency,
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixManifestViews(_ items: [SkillMixManifest]) -> [SkillMixManifestView] {
        var views: [SkillMixManifestView] = []
        for item in items {
            views.append(toSkillMixManifestView(item))
        }
        return views
    }

    static func sumSkillMixManifestView(_ view: SkillMixManifestView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedSequence) + parsedThreshold
    }
}
