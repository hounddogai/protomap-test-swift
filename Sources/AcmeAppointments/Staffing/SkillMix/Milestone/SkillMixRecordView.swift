import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix record.
    final class SkillMixRecordView {
        var codeText: String
        var title: String
        var pinnedText: String
        var bed: String
        var score: String
        var retries: String
        var statusLabel: String

        init(codeText: String, title: String, pinnedText: String, bed: String, score: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.pinnedText = pinnedText
            self.bed = bed
            self.score = score
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixRecordView(_ item: SkillMixRecord) -> SkillMixRecordView {
        return SkillMixRecordView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            pinnedText: "\(item.pinned)",
            bed: item.bed,
            score: String(format: "%.2f", item.score),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixRecordViews(_ items: [SkillMixRecord]) -> [SkillMixRecordView] {
        var views: [SkillMixRecordView] = []
        for item in items {
            views.append(toSkillMixRecordView(item))
        }
        return views
    }

    static func sumSkillMixRecordView(_ view: SkillMixRecordView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedScore + Double(parsedRetries)
    }
}
