import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding target.
    final class RoundingTargetView {
        var code: String
        var label: String
        var pinned: String
        var descriptionText: String
        var procedureCode: String
        var margin: String
        var versionText: String
        var retries: String
        var dosageMg: String
        var sequenceText: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, label: String, pinned: String, descriptionText: String, procedureCode: String, margin: String, versionText: String, retries: String, dosageMg: String, sequenceText: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.descriptionText = descriptionText
            self.procedureCode = procedureCode
            self.margin = margin
            self.versionText = versionText
            self.retries = retries
            self.dosageMg = dosageMg
            self.sequenceText = sequenceText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingTargetView(_ item: RoundingTarget) -> RoundingTargetView {
        return RoundingTargetView(
            code: item.code,
            label: item.label,
            pinned: "\(item.pinned)",
            descriptionText: Kit.Text.truncate(item.description, limit: 80),
            procedureCode: item.procedureCode,
            margin: String(format: "%.2f", item.margin),
            versionText: String(item.version),
            retries: String(item.retries),
            dosageMg: String(format: "%.2f", item.dosageMg),
            sequenceText: String(item.sequence),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingTargetViews(_ items: [RoundingTarget]) -> [RoundingTargetView] {
        var views: [RoundingTargetView] = []
        for item in items {
            views.append(toRoundingTargetView(item))
        }
        return views
    }

    static func sumRoundingTargetView(_ view: RoundingTargetView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedMargin + Double(parsedVersion) + Double(parsedRetries)
    }
}
