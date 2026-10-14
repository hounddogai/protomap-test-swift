import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist variance.
    final class WorklistVarianceView {
        var code: String
        var label: String
        var patientRef: String
        var ratio: String
        var statusLabel: String

        init(code: String, label: String, patientRef: String, ratio: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistVarianceView(_ item: WorklistVariance) -> WorklistVarianceView {
        return WorklistVarianceView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistVarianceViews(_ items: [WorklistVariance]) -> [WorklistVarianceView] {
        var views: [WorklistVarianceView] = []
        for item in items {
            views.append(toWorklistVarianceView(item))
        }
        return views
    }

    static func sumWorklistVarianceView(_ view: WorklistVarianceView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
