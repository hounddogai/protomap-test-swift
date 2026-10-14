import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a manual care gap metric.
    final class ManualCareGapMetricView {
        var codeText: String
        var name: String
        var revisionText: String
        var specialtyText: String
        var region: String
        var visibleText: String
        var label: String
        var batchSizeText: String
        var statusLabel: String

        init(codeText: String, name: String, revisionText: String, specialtyText: String, region: String, visibleText: String, label: String, batchSizeText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.revisionText = revisionText
            self.specialtyText = specialtyText
            self.region = region
            self.visibleText = visibleText
            self.label = label
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toManualCareGapMetricView(_ item: ManualCareGapMetric) -> ManualCareGapMetricView {
        return ManualCareGapMetricView(
            codeText: item.code,
            name: item.name,
            revisionText: String(item.revision),
            specialtyText: item.specialty,
            region: item.region,
            visibleText: "\(item.visible)",
            label: item.label,
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCareGapMetricViews(_ items: [ManualCareGapMetric]) -> [ManualCareGapMetricView] {
        var views: [ManualCareGapMetricView] = []
        for item in items {
            views.append(toManualCareGapMetricView(item))
        }
        return views
    }

    static func sumManualCareGapMetricView(_ view: ManualCareGapMetricView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedRevision) + Double(parsedBatchSize)
    }
}
