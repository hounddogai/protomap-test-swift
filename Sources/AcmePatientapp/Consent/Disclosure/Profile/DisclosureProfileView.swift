import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure profile.
    final class DisclosureProfileView {
        var codeText: String
        var name: String
        var retries: String
        var maximum: String
        var weightText: String
        var allergy: String
        var bed: String
        var checksumText: String
        var pinned: String
        var updatedAt: String
        var revisionText: String
        var statusLabel: String

        init(codeText: String, name: String, retries: String, maximum: String, weightText: String, allergy: String, bed: String, checksumText: String, pinned: String, updatedAt: String, revisionText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.retries = retries
            self.maximum = maximum
            self.weightText = weightText
            self.allergy = allergy
            self.bed = bed
            self.checksumText = checksumText
            self.pinned = pinned
            self.updatedAt = updatedAt
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureProfileView(_ item: DisclosureProfile) -> DisclosureProfileView {
        return DisclosureProfileView(
            codeText: item.code,
            name: item.name,
            retries: String(item.retries),
            maximum: String(format: "%.2f", item.maximum),
            weightText: String(format: "%.2f", item.weight),
            allergy: item.allergy,
            bed: Kit.Text.truncate(item.bed, limit: 40),
            checksumText: Kit.Text.truncate(item.checksum, limit: 120),
            pinned: "\(item.pinned)",
            updatedAt: String(item.updatedAt),
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureProfileViews(_ items: [DisclosureProfile]) -> [DisclosureProfileView] {
        var views: [DisclosureProfileView] = []
        for item in items {
            views.append(toDisclosureProfileView(item))
        }
        return views
    }

    static func sumDisclosureProfileView(_ view: DisclosureProfileView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedRetries) + parsedMaximum + parsedWeight
    }
}
