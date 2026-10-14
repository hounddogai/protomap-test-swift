import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped accession checkpoint.
    final class CappedAccessionCheckpointView {
        var code: String
        var nameText: String
        var attempts: String
        var visible: String
        var patientRef: String
        var statusLabel: String

        init(code: String, nameText: String, attempts: String, visible: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.attempts = attempts
            self.visible = visible
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toCappedAccessionCheckpointView(_ item: CappedAccessionCheckpoint) -> CappedAccessionCheckpointView {
        return CappedAccessionCheckpointView(
            code: item.code,
            nameText: item.name,
            attempts: String(item.attempts),
            visible: "\(item.visible)",
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedAccessionCheckpointViews(_ items: [CappedAccessionCheckpoint]) -> [CappedAccessionCheckpointView] {
        var views: [CappedAccessionCheckpointView] = []
        for item in items {
            views.append(toCappedAccessionCheckpointView(item))
        }
        return views
    }

    static func sumCappedAccessionCheckpointView(_ view: CappedAccessionCheckpointView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
