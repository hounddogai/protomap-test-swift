import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment agreement.
    final class AssessmentAgreementView {
        var codeText: String
        var label: String
        var versionText: String
        var summary: String
        var batchSizeText: String
        var ratioText: String
        var windowDays: String
        var threshold: String
        var name: String
        var patientRef: String
        var statusLabel: String

        init(codeText: String, label: String, versionText: String, summary: String, batchSizeText: String, ratioText: String, windowDays: String, threshold: String, name: String, patientRef: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.versionText = versionText
            self.summary = summary
            self.batchSizeText = batchSizeText
            self.ratioText = ratioText
            self.windowDays = windowDays
            self.threshold = threshold
            self.name = name
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentAgreementView(_ item: AssessmentAgreement) -> AssessmentAgreementView {
        return AssessmentAgreementView(
            codeText: item.code,
            label: item.label,
            versionText: String(item.version),
            summary: Kit.Text.truncate(item.summary, limit: 64),
            batchSizeText: String(item.batchSize),
            ratioText: String(format: "%.2f", item.ratio),
            windowDays: String(item.windowDays),
            threshold: String(format: "%.2f", item.threshold),
            name: item.name,
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentAgreementViews(_ items: [AssessmentAgreement]) -> [AssessmentAgreementView] {
        var views: [AssessmentAgreementView] = []
        for item in items {
            views.append(toAssessmentAgreementView(item))
        }
        return views
    }

    static func sumAssessmentAgreementView(_ view: AssessmentAgreementView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedVersion) + Double(parsedBatchSize) + parsedRatio
    }
}
