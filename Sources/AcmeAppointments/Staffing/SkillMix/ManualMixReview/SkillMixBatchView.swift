import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix batch.
    final class SkillMixBatchView {
        var code: String
        var title: String
        var bedText: String
        var summaryText: String
        var minimumText: String
        var unit: String
        var label: String
        var visible: String
        var statusLabel: String

        init(code: String, title: String, bedText: String, summaryText: String, minimumText: String, unit: String, label: String, visible: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.bedText = bedText
            self.summaryText = summaryText
            self.minimumText = minimumText
            self.unit = unit
            self.label = label
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixBatchView(_ item: SkillMixBatch) -> SkillMixBatchView {
        return SkillMixBatchView(
            code: item.code,
            title: item.title,
            bedText: item.bed,
            summaryText: Kit.Text.truncate(item.summary, limit: 40),
            minimumText: String(format: "%.2f", item.minimum),
            unit: Kit.Text.truncate(item.unit, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 120),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixBatchViews(_ items: [SkillMixBatch]) -> [SkillMixBatchView] {
        var views: [SkillMixBatchView] = []
        for item in items {
            views.append(toSkillMixBatchView(item))
        }
        return views
    }

    static func sumSkillMixBatchView(_ view: SkillMixBatchView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
