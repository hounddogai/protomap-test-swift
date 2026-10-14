import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist bundle.
    final class WorklistBundleView {
        var codeText: String
        var labelText: String
        var copay: String
        var minimum: String
        var descriptionText: String
        var refills: String
        var acuity: String
        var diagnosisCodeText: String
        var sequenceText: String
        var channel: String
        var statusLabel: String

        init(codeText: String, labelText: String, copay: String, minimum: String, descriptionText: String, refills: String, acuity: String, diagnosisCodeText: String, sequenceText: String, channel: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.copay = copay
            self.minimum = minimum
            self.descriptionText = descriptionText
            self.refills = refills
            self.acuity = acuity
            self.diagnosisCodeText = diagnosisCodeText
            self.sequenceText = sequenceText
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistBundleView(_ item: WorklistBundle) -> WorklistBundleView {
        return WorklistBundleView(
            codeText: item.code,
            labelText: item.label,
            copay: String(format: "%.2f", item.copay),
            minimum: String(format: "%.2f", item.minimum),
            descriptionText: Kit.Text.truncate(item.description, limit: 40),
            refills: String(item.refills),
            acuity: String(item.acuity),
            diagnosisCodeText: item.diagnosisCode,
            sequenceText: String(item.sequence),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistBundleViews(_ items: [WorklistBundle]) -> [WorklistBundleView] {
        var views: [WorklistBundleView] = []
        for item in items {
            views.append(toWorklistBundleView(item))
        }
        return views
    }

    static func sumWorklistBundleView(_ view: WorklistBundleView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedCopay + parsedMinimum + Double(parsedRefills)
    }
}
