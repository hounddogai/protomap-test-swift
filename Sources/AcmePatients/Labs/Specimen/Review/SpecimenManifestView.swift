import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen manifest.
    final class SpecimenManifestView {
        var codeText: String
        var label: String
        var country: String
        var refillsText: String
        var attemptsText: String
        var statusLabel: String

        init(codeText: String, label: String, country: String, refillsText: String, attemptsText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.country = country
            self.refillsText = refillsText
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenManifestView(_ item: SpecimenManifest) -> SpecimenManifestView {
        return SpecimenManifestView(
            codeText: item.code,
            label: item.label,
            country: Kit.Text.truncate(item.country, limit: 120),
            refillsText: String(item.refills),
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenManifestViews(_ items: [SpecimenManifest]) -> [SpecimenManifestView] {
        var views: [SpecimenManifestView] = []
        for item in items {
            views.append(toSpecimenManifestView(item))
        }
        return views
    }

    static func sumSpecimenManifestView(_ view: SpecimenManifestView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedRefills) + Double(parsedAttempts)
    }
}
