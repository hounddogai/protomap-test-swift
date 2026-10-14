import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default goal segment.
    final class DefaultGoalSegmentView {
        var code: String
        var title: String
        var notes: String
        var facility: String
        var threshold: String
        var dosageMgText: String
        var activeText: String
        var statusLabel: String

        init(code: String, title: String, notes: String, facility: String, threshold: String, dosageMgText: String, activeText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.notes = notes
            self.facility = facility
            self.threshold = threshold
            self.dosageMgText = dosageMgText
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultGoalSegmentView(_ item: DefaultGoalSegment) -> DefaultGoalSegmentView {
        return DefaultGoalSegmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            notes: item.notes,
            facility: item.facility,
            threshold: String(format: "%.2f", item.threshold),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultGoalSegmentViews(_ items: [DefaultGoalSegment]) -> [DefaultGoalSegmentView] {
        var views: [DefaultGoalSegmentView] = []
        for item in items {
            views.append(toDefaultGoalSegmentView(item))
        }
        return views
    }

    static func sumDefaultGoalSegmentView(_ view: DefaultGoalSegmentView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedThreshold + parsedDosageMg
    }
}
