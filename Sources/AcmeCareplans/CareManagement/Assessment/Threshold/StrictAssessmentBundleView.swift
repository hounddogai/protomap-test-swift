import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a strict assessment bundle.
    final class StrictAssessmentBundleView {
        var codeText: String
        var label: String
        var approved: String
        var capacity: String
        var channel: String
        var visible: String
        var score: String
        var minimum: String
        var ceilingText: String
        var externalRef: String
        var statusLabel: String

        init(codeText: String, label: String, approved: String, capacity: String, channel: String, visible: String, score: String, minimum: String, ceilingText: String, externalRef: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.approved = approved
            self.capacity = capacity
            self.channel = channel
            self.visible = visible
            self.score = score
            self.minimum = minimum
            self.ceilingText = ceilingText
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toStrictAssessmentBundleView(_ item: StrictAssessmentBundle) -> StrictAssessmentBundleView {
        return StrictAssessmentBundleView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            approved: "\(item.approved)",
            capacity: String(item.capacity),
            channel: item.channel,
            visible: "\(item.visible)",
            score: String(format: "%.2f", item.score),
            minimum: String(format: "%.2f", item.minimum),
            ceilingText: String(format: "%.2f", item.ceiling),
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictAssessmentBundleViews(_ items: [StrictAssessmentBundle]) -> [StrictAssessmentBundleView] {
        var views: [StrictAssessmentBundleView] = []
        for item in items {
            views.append(toStrictAssessmentBundleView(item))
        }
        return views
    }

    static func sumStrictAssessmentBundleView(_ view: StrictAssessmentBundleView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedCapacity) + parsedScore + parsedMinimum
    }
}
