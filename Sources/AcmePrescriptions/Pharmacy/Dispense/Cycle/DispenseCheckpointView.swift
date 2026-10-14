import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense checkpoint.
    final class DispenseCheckpointView {
        var codeText: String
        var titleText: String
        var durationMinutes: String
        var diagnosisCode: String
        var label: String
        var maximumText: String
        var statusLabel: String

        init(codeText: String, titleText: String, durationMinutes: String, diagnosisCode: String, label: String, maximumText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.durationMinutes = durationMinutes
            self.diagnosisCode = diagnosisCode
            self.label = label
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseCheckpointView(_ item: DispenseCheckpoint) -> DispenseCheckpointView {
        return DispenseCheckpointView(
            codeText: item.code,
            titleText: item.title,
            durationMinutes: String(item.durationMinutes),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            label: item.label,
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseCheckpointViews(_ items: [DispenseCheckpoint]) -> [DispenseCheckpointView] {
        var views: [DispenseCheckpointView] = []
        for item in items {
            views.append(toDispenseCheckpointView(item))
        }
        return views
    }

    static func sumDispenseCheckpointView(_ view: DispenseCheckpointView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedDurationMinutes) + parsedMaximum
    }
}
