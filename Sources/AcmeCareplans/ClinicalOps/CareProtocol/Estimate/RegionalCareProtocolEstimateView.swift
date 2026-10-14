import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a regional care protocol estimate.
    final class RegionalCareProtocolEstimateView {
        var code: String
        var label: String
        var unitText: String
        var copay: String
        var batchSize: String
        var weight: String
        var patientRefText: String
        var versionText: String
        var specialty: String
        var statusLabel: String

        init(code: String, label: String, unitText: String, copay: String, batchSize: String, weight: String, patientRefText: String, versionText: String, specialty: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.unitText = unitText
            self.copay = copay
            self.batchSize = batchSize
            self.weight = weight
            self.patientRefText = patientRefText
            self.versionText = versionText
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCareProtocolEstimateView(_ item: RegionalCareProtocolEstimate) -> RegionalCareProtocolEstimateView {
        return RegionalCareProtocolEstimateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            unitText: item.unit,
            copay: String(format: "%.2f", item.copay),
            batchSize: String(item.batchSize),
            weight: String(format: "%.2f", item.weight),
            patientRefText: item.patientRef,
            versionText: String(item.version),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCareProtocolEstimateViews(_ items: [RegionalCareProtocolEstimate]) -> [RegionalCareProtocolEstimateView] {
        var views: [RegionalCareProtocolEstimateView] = []
        for item in items {
            views.append(toRegionalCareProtocolEstimateView(item))
        }
        return views
    }

    static func sumRegionalCareProtocolEstimateView(_ view: RegionalCareProtocolEstimateView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedCopay + Double(parsedBatchSize) + parsedWeight
    }
}
