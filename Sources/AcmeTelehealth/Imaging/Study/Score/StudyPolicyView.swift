import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study policy.
    final class StudyPolicyView {
        var code: String
        var titleText: String
        var notesText: String
        var active: String
        var timezone: String
        var createdAt: String
        var region: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, titleText: String, notesText: String, active: String, timezone: String, createdAt: String, region: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.notesText = notesText
            self.active = active
            self.timezone = timezone
            self.createdAt = createdAt
            self.region = region
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toStudyPolicyView(_ item: StudyPolicy) -> StudyPolicyView {
        return StudyPolicyView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: Kit.Text.truncate(item.title, limit: 40),
            notesText: Kit.Text.truncate(item.notes, limit: 120),
            active: "\(item.active)",
            timezone: item.timezone,
            createdAt: String(item.createdAt),
            region: item.region,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyPolicyViews(_ items: [StudyPolicy]) -> [StudyPolicyView] {
        var views: [StudyPolicyView] = []
        for item in items {
            views.append(toStudyPolicyView(item))
        }
        return views
    }

    static func sumStudyPolicyView(_ view: StudyPolicyView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedCreatedAt) + parsedDosageMg
    }
}
