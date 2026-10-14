import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census estimate.
    final class CensusEstimateView {
        var code: String
        var label: String
        var versionText: String
        var visitMinutes: String
        var weightText: String
        var diagnosisCode: String
        var batchSize: String
        var revision: String
        var attemptsText: String
        var statusLabel: String

        init(code: String, label: String, versionText: String, visitMinutes: String, weightText: String, diagnosisCode: String, batchSize: String, revision: String, attemptsText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.versionText = versionText
            self.visitMinutes = visitMinutes
            self.weightText = weightText
            self.diagnosisCode = diagnosisCode
            self.batchSize = batchSize
            self.revision = revision
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toCensusEstimateView(_ item: CensusEstimate) -> CensusEstimateView {
        return CensusEstimateView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            versionText: String(item.version),
            visitMinutes: String(item.visitMinutes),
            weightText: String(format: "%.2f", item.weight),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            batchSize: String(item.batchSize),
            revision: String(item.revision),
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusEstimateViews(_ items: [CensusEstimate]) -> [CensusEstimateView] {
        var views: [CensusEstimateView] = []
        for item in items {
            views.append(toCensusEstimateView(item))
        }
        return views
    }

    static func sumCensusEstimateView(_ view: CensusEstimateView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedVersion) + Double(parsedVisitMinutes) + parsedWeight
    }
}
