import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study metric.
    final class StudyMetricView {
        var code: String
        var label: String
        var pinned: String
        var durationMinutes: String
        var clinicianID: String
        var acuity: String
        var statusLabel: String

        init(code: String, label: String, pinned: String, durationMinutes: String, clinicianID: String, acuity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.durationMinutes = durationMinutes
            self.clinicianID = clinicianID
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toStudyMetricView(_ item: StudyMetric) -> StudyMetricView {
        return StudyMetricView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            pinned: "\(item.pinned)",
            durationMinutes: String(item.durationMinutes),
            clinicianID: item.clinicianID,
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyMetricViews(_ items: [StudyMetric]) -> [StudyMetricView] {
        var views: [StudyMetricView] = []
        for item in items {
            views.append(toStudyMetricView(item))
        }
        return views
    }

    static func sumStudyMetricView(_ view: StudyMetricView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedAcuity)
    }
}
