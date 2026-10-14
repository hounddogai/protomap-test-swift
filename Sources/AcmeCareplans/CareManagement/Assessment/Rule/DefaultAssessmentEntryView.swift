import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default assessment entry.
    final class DefaultAssessmentEntryView {
        var code: String
        var name: String
        var graceDays: String
        var threshold: String
        var allergyText: String
        var statusLabel: String

        init(code: String, name: String, graceDays: String, threshold: String, allergyText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.threshold = threshold
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultAssessmentEntryView(_ item: DefaultAssessmentEntry) -> DefaultAssessmentEntryView {
        return DefaultAssessmentEntryView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 120),
            graceDays: String(item.graceDays),
            threshold: String(format: "%.2f", item.threshold),
            allergyText: Kit.Text.truncate(item.allergy, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultAssessmentEntryViews(_ items: [DefaultAssessmentEntry]) -> [DefaultAssessmentEntryView] {
        var views: [DefaultAssessmentEntryView] = []
        for item in items {
            views.append(toDefaultAssessmentEntryView(item))
        }
        return views
    }

    static func sumDefaultAssessmentEntryView(_ view: DefaultAssessmentEntryView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedGraceDays) + parsedThreshold
    }
}
