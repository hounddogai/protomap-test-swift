import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool baseline.
    final class FloatPoolBaselineView {
        var codeText: String
        var labelText: String
        var patientRefText: String
        var startsAt: String
        var segmentText: String
        var createdAtText: String
        var dosageMg: String
        var statusLabel: String

        init(codeText: String, labelText: String, patientRefText: String, startsAt: String, segmentText: String, createdAtText: String, dosageMg: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.patientRefText = patientRefText
            self.startsAt = startsAt
            self.segmentText = segmentText
            self.createdAtText = createdAtText
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolBaselineView(_ item: FloatPoolBaseline) -> FloatPoolBaselineView {
        return FloatPoolBaselineView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            startsAt: String(item.startsAt),
            segmentText: item.segment,
            createdAtText: String(item.createdAt),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolBaselineViews(_ items: [FloatPoolBaseline]) -> [FloatPoolBaselineView] {
        var views: [FloatPoolBaselineView] = []
        for item in items {
            views.append(toFloatPoolBaselineView(item))
        }
        return views
    }

    static func sumFloatPoolBaselineView(_ view: FloatPoolBaselineView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedCreatedAt) + parsedDosageMg
    }
}
