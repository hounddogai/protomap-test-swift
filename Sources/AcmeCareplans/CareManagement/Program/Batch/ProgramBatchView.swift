import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program batch.
    final class ProgramBatchView {
        var code: String
        var label: String
        var diagnosisCode: String
        var regionText: String
        var currency: String
        var minimumText: String
        var refills: String
        var threshold: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCode: String, regionText: String, currency: String, minimumText: String, refills: String, threshold: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.regionText = regionText
            self.currency = currency
            self.minimumText = minimumText
            self.refills = refills
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toProgramBatchView(_ item: ProgramBatch) -> ProgramBatchView {
        return ProgramBatchView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 64),
            diagnosisCode: item.diagnosisCode,
            regionText: item.region,
            currency: Kit.Text.truncate(item.currency, limit: 80),
            minimumText: String(format: "%.2f", item.minimum),
            refills: String(item.refills),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramBatchViews(_ items: [ProgramBatch]) -> [ProgramBatchView] {
        var views: [ProgramBatchView] = []
        for item in items {
            views.append(toProgramBatchView(item))
        }
        return views
    }

    static func sumProgramBatchView(_ view: ProgramBatchView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedMinimum + Double(parsedRefills) + parsedThreshold
    }
}
