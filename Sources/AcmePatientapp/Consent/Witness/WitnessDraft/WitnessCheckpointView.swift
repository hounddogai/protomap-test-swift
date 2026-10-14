import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness checkpoint.
    final class WitnessCheckpointView {
        var code: String
        var titleText: String
        var procedureCode: String
        var maximum: String
        var version: String
        var pinned: String
        var statusLabel: String

        init(code: String, titleText: String, procedureCode: String, maximum: String, version: String, pinned: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.version = version
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessCheckpointView(_ item: WitnessCheckpoint) -> WitnessCheckpointView {
        return WitnessCheckpointView(
            code: item.code,
            titleText: item.title,
            procedureCode: item.procedureCode,
            maximum: String(format: "%.2f", item.maximum),
            version: String(item.version),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessCheckpointViews(_ items: [WitnessCheckpoint]) -> [WitnessCheckpointView] {
        var views: [WitnessCheckpointView] = []
        for item in items {
            views.append(toWitnessCheckpointView(item))
        }
        return views
    }

    static func sumWitnessCheckpointView(_ view: WitnessCheckpointView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedMaximum + Double(parsedVersion)
    }
}
