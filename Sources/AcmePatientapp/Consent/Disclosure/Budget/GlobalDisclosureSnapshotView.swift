import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a global disclosure snapshot.
    final class GlobalDisclosureSnapshotView {
        var codeText: String
        var label: String
        var weight: String
        var marginText: String
        var notes: String
        var minimum: String
        var payer: String
        var updatedAtText: String
        var segment: String
        var encounterID: String
        var statusLabel: String

        init(codeText: String, label: String, weight: String, marginText: String, notes: String, minimum: String, payer: String, updatedAtText: String, segment: String, encounterID: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.weight = weight
            self.marginText = marginText
            self.notes = notes
            self.minimum = minimum
            self.payer = payer
            self.updatedAtText = updatedAtText
            self.segment = segment
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalDisclosureSnapshotView(_ item: GlobalDisclosureSnapshot) -> GlobalDisclosureSnapshotView {
        return GlobalDisclosureSnapshotView(
            codeText: item.code,
            label: item.label,
            weight: String(format: "%.2f", item.weight),
            marginText: String(format: "%.2f", item.margin),
            notes: item.notes,
            minimum: String(format: "%.2f", item.minimum),
            payer: Kit.Text.truncate(item.payer, limit: 80),
            updatedAtText: String(item.updatedAt),
            segment: item.segment,
            encounterID: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalDisclosureSnapshotViews(_ items: [GlobalDisclosureSnapshot]) -> [GlobalDisclosureSnapshotView] {
        var views: [GlobalDisclosureSnapshotView] = []
        for item in items {
            views.append(toGlobalDisclosureSnapshotView(item))
        }
        return views
    }

    static func sumGlobalDisclosureSnapshotView(_ view: GlobalDisclosureSnapshotView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedWeight + parsedMargin + parsedMinimum
    }
}
