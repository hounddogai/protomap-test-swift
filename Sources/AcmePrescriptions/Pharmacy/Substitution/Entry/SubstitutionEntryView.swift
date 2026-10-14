import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution entry.
    final class SubstitutionEntryView {
        var code: String
        var label: String
        var reviewer: String
        var region: String
        var minimum: String
        var externalRef: String
        var version: String
        var weightText: String
        var statusLabel: String

        init(code: String, label: String, reviewer: String, region: String, minimum: String, externalRef: String, version: String, weightText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.region = region
            self.minimum = minimum
            self.externalRef = externalRef
            self.version = version
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionEntryView(_ item: SubstitutionEntry) -> SubstitutionEntryView {
        return SubstitutionEntryView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            reviewer: item.reviewer,
            region: item.region,
            minimum: String(format: "%.2f", item.minimum),
            externalRef: item.externalRef,
            version: String(item.version),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionEntryViews(_ items: [SubstitutionEntry]) -> [SubstitutionEntryView] {
        var views: [SubstitutionEntryView] = []
        for item in items {
            views.append(toSubstitutionEntryView(item))
        }
        return views
    }

    static func sumSubstitutionEntryView(_ view: SubstitutionEntryView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedMinimum + Double(parsedVersion) + parsedWeight
    }
}
