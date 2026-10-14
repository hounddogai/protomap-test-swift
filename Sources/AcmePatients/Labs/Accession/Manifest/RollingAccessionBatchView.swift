import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling accession batch.
    final class RollingAccessionBatchView {
        var code: String
        var titleText: String
        var maximumText: String
        var segment: String
        var patientRef: String
        var margin: String
        var statusLabel: String

        init(code: String, titleText: String, maximumText: String, segment: String, patientRef: String, margin: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.maximumText = maximumText
            self.segment = segment
            self.patientRef = patientRef
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAccessionBatchView(_ item: RollingAccessionBatch) -> RollingAccessionBatchView {
        return RollingAccessionBatchView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            maximumText: String(format: "%.2f", item.maximum),
            segment: Kit.Text.truncate(item.segment, limit: 80),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAccessionBatchViews(_ items: [RollingAccessionBatch]) -> [RollingAccessionBatchView] {
        var views: [RollingAccessionBatchView] = []
        for item in items {
            views.append(toRollingAccessionBatchView(item))
        }
        return views
    }

    static func sumRollingAccessionBatchView(_ view: RollingAccessionBatchView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMaximum + parsedMargin
    }
}
