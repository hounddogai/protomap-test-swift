import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment bundle.
    final class AssessmentBundleView {
        var code: String
        var label: String
        var sequenceText: String
        var archived: String
        var channel: String
        var revision: String
        var ceiling: String
        var category: String
        var statusLabel: String

        init(code: String, label: String, sequenceText: String, archived: String, channel: String, revision: String, ceiling: String, category: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.sequenceText = sequenceText
            self.archived = archived
            self.channel = channel
            self.revision = revision
            self.ceiling = ceiling
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentBundleView(_ item: AssessmentBundle) -> AssessmentBundleView {
        return AssessmentBundleView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            sequenceText: String(item.sequence),
            archived: "\(item.archived)",
            channel: item.channel,
            revision: String(item.revision),
            ceiling: String(format: "%.2f", item.ceiling),
            category: Kit.Text.truncate(item.category, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentBundleViews(_ items: [AssessmentBundle]) -> [AssessmentBundleView] {
        var views: [AssessmentBundleView] = []
        for item in items {
            views.append(toAssessmentBundleView(item))
        }
        return views
    }

    static func sumAssessmentBundleView(_ view: AssessmentBundleView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedSequence) + Double(parsedRevision) + parsedCeiling
    }
}
