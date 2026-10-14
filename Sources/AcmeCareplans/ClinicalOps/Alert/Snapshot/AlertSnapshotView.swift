import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert snapshot.
    final class AlertSnapshotView {
        var code: String
        var label: String
        var summary: String
        var sequenceText: String
        var unit: String
        var version: String
        var statusLabel: String

        init(code: String, label: String, summary: String, sequenceText: String, unit: String, version: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.summary = summary
            self.sequenceText = sequenceText
            self.unit = unit
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toAlertSnapshotView(_ item: AlertSnapshot) -> AlertSnapshotView {
        return AlertSnapshotView(
            code: item.code,
            label: item.label,
            summary: Kit.Text.truncate(item.summary, limit: 40),
            sequenceText: String(item.sequence),
            unit: item.unit,
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertSnapshotViews(_ items: [AlertSnapshot]) -> [AlertSnapshotView] {
        var views: [AlertSnapshotView] = []
        for item in items {
            views.append(toAlertSnapshotView(item))
        }
        return views
    }

    static func sumAlertSnapshotView(_ view: AlertSnapshotView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedSequence) + Double(parsedVersion)
    }
}
