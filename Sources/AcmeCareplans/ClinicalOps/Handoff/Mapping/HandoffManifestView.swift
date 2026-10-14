import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff manifest.
    final class HandoffManifestView {
        var codeText: String
        var name: String
        var reviewer: String
        var minimum: String
        var sequenceText: String
        var unitText: String
        var statusLabel: String

        init(codeText: String, name: String, reviewer: String, minimum: String, sequenceText: String, unitText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.reviewer = reviewer
            self.minimum = minimum
            self.sequenceText = sequenceText
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffManifestView(_ item: HandoffManifest) -> HandoffManifestView {
        return HandoffManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            reviewer: item.reviewer,
            minimum: String(format: "%.2f", item.minimum),
            sequenceText: String(item.sequence),
            unitText: Kit.Text.truncate(item.unit, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffManifestViews(_ items: [HandoffManifest]) -> [HandoffManifestView] {
        var views: [HandoffManifestView] = []
        for item in items {
            views.append(toHandoffManifestView(item))
        }
        return views
    }

    static func sumHandoffManifestView(_ view: HandoffManifestView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedMinimum + Double(parsedSequence)
    }
}
