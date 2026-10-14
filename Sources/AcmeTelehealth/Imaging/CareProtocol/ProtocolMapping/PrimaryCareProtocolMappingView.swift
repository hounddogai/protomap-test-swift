import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a primary care protocol mapping.
    final class PrimaryCareProtocolMappingView {
        var code: String
        var labelText: String
        var batchSizeText: String
        var patientRef: String
        var localeText: String
        var description: String
        var diagnosisCode: String
        var facility: String
        var weightText: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, labelText: String, batchSizeText: String, patientRef: String, localeText: String, description: String, diagnosisCode: String, facility: String, weightText: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.batchSizeText = batchSizeText
            self.patientRef = patientRef
            self.localeText = localeText
            self.description = description
            self.diagnosisCode = diagnosisCode
            self.facility = facility
            self.weightText = weightText
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCareProtocolMappingView(_ item: PrimaryCareProtocolMapping) -> PrimaryCareProtocolMappingView {
        return PrimaryCareProtocolMappingView(
            code: item.code,
            labelText: item.label,
            batchSizeText: String(item.batchSize),
            patientRef: item.patientRef,
            localeText: item.locale,
            description: item.description,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            facility: Kit.Text.truncate(item.facility, limit: 120),
            weightText: String(format: "%.2f", item.weight),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCareProtocolMappingViews(_ items: [PrimaryCareProtocolMapping]) -> [PrimaryCareProtocolMappingView] {
        var views: [PrimaryCareProtocolMappingView] = []
        for item in items {
            views.append(toPrimaryCareProtocolMappingView(item))
        }
        return views
    }

    static func sumPrimaryCareProtocolMappingView(_ view: PrimaryCareProtocolMappingView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedBatchSize) + parsedWeight + Double(parsedUpdatedAt)
    }
}
