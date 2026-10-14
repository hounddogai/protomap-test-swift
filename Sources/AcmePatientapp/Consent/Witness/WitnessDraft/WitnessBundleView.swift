import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness bundle.
    final class WitnessBundleView {
        var code: String
        var labelText: String
        var revision: String
        var minimum: String
        var patientRefText: String
        var statusLabel: String

        init(code: String, labelText: String, revision: String, minimum: String, patientRefText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.revision = revision
            self.minimum = minimum
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessBundleView(_ item: WitnessBundle) -> WitnessBundleView {
        return WitnessBundleView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            revision: String(item.revision),
            minimum: String(format: "%.2f", item.minimum),
            patientRefText: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessBundleViews(_ items: [WitnessBundle]) -> [WitnessBundleView] {
        var views: [WitnessBundleView] = []
        for item in items {
            views.append(toWitnessBundleView(item))
        }
        return views
    }

    static func sumWitnessBundleView(_ view: WitnessBundleView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedRevision) + parsedMinimum
    }
}
