import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form snapshot.
    final class ConsentFormSnapshotView {
        var codeText: String
        var label: String
        var createdAt: String
        var weightText: String
        var category: String
        var margin: String
        var threshold: String
        var regionText: String
        var statusLabel: String

        init(codeText: String, label: String, createdAt: String, weightText: String, category: String, margin: String, threshold: String, regionText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.createdAt = createdAt
            self.weightText = weightText
            self.category = category
            self.margin = margin
            self.threshold = threshold
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormSnapshotView(_ item: ConsentFormSnapshot) -> ConsentFormSnapshotView {
        return ConsentFormSnapshotView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            createdAt: String(item.createdAt),
            weightText: String(format: "%.2f", item.weight),
            category: item.category,
            margin: String(format: "%.2f", item.margin),
            threshold: String(format: "%.2f", item.threshold),
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormSnapshotViews(_ items: [ConsentFormSnapshot]) -> [ConsentFormSnapshotView] {
        var views: [ConsentFormSnapshotView] = []
        for item in items {
            views.append(toConsentFormSnapshotView(item))
        }
        return views
    }

    static func sumConsentFormSnapshotView(_ view: ConsentFormSnapshotView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedCreatedAt) + parsedWeight + parsedMargin
    }
}
