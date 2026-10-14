import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a weighted disclosure snapshot.
    final class WeightedDisclosureSnapshotView {
        var code: String
        var label: String
        var attemptsText: String
        var reviewer: String
        var weight: String
        var endsAt: String
        var locale: String
        var clinicianID: String
        var summary: String
        var costText: String
        var statusLabel: String

        init(code: String, label: String, attemptsText: String, reviewer: String, weight: String, endsAt: String, locale: String, clinicianID: String, summary: String, costText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.attemptsText = attemptsText
            self.reviewer = reviewer
            self.weight = weight
            self.endsAt = endsAt
            self.locale = locale
            self.clinicianID = clinicianID
            self.summary = summary
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedDisclosureSnapshotView(_ item: WeightedDisclosureSnapshot) -> WeightedDisclosureSnapshotView {
        return WeightedDisclosureSnapshotView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 120),
            attemptsText: String(item.attempts),
            reviewer: item.reviewer,
            weight: String(format: "%.2f", item.weight),
            endsAt: String(item.endsAt),
            locale: item.locale,
            clinicianID: item.clinicianID,
            summary: item.summary,
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedDisclosureSnapshotViews(_ items: [WeightedDisclosureSnapshot]) -> [WeightedDisclosureSnapshotView] {
        var views: [WeightedDisclosureSnapshotView] = []
        for item in items {
            views.append(toWeightedDisclosureSnapshotView(item))
        }
        return views
    }

    static func sumWeightedDisclosureSnapshotView(_ view: WeightedDisclosureSnapshotView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedAttempts) + parsedWeight + Double(parsedEndsAt)
    }
}
