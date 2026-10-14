import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy formulary snapshot.
    final class LegacyFormularySnapshotView {
        var codeText: String
        var title: String
        var source: String
        var summary: String
        var weightText: String
        var nameText: String
        var statusLabel: String

        init(codeText: String, title: String, source: String, summary: String, weightText: String, nameText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.source = source
            self.summary = summary
            self.weightText = weightText
            self.nameText = nameText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyFormularySnapshotView(_ item: LegacyFormularySnapshot) -> LegacyFormularySnapshotView {
        return LegacyFormularySnapshotView(
            codeText: item.code,
            title: item.title,
            source: item.source,
            summary: Kit.Text.truncate(item.summary, limit: 40),
            weightText: String(format: "%.2f", item.weight),
            nameText: Kit.Text.truncate(item.name, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyFormularySnapshotViews(_ items: [LegacyFormularySnapshot]) -> [LegacyFormularySnapshotView] {
        var views: [LegacyFormularySnapshotView] = []
        for item in items {
            views.append(toLegacyFormularySnapshotView(item))
        }
        return views
    }

    static func sumLegacyFormularySnapshotView(_ view: LegacyFormularySnapshotView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
