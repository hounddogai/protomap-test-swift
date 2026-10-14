import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality rule.
    final class ModalityRuleView {
        var code: String
        var title: String
        var label: String
        var visible: String
        var approved: String
        var discountText: String
        var attempts: String
        var segmentText: String
        var statusLabel: String

        init(code: String, title: String, label: String, visible: String, approved: String, discountText: String, attempts: String, segmentText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.label = label
            self.visible = visible
            self.approved = approved
            self.discountText = discountText
            self.attempts = attempts
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toModalityRuleView(_ item: ModalityRule) -> ModalityRuleView {
        return ModalityRuleView(
            code: item.code,
            title: item.title,
            label: item.label,
            visible: "\(item.visible)",
            approved: "\(item.approved)",
            discountText: String(format: "%.2f", item.discount),
            attempts: String(item.attempts),
            segmentText: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityRuleViews(_ items: [ModalityRule]) -> [ModalityRuleView] {
        var views: [ModalityRuleView] = []
        for item in items {
            views.append(toModalityRuleView(item))
        }
        return views
    }

    static func sumModalityRuleView(_ view: ModalityRuleView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedDiscount + Double(parsedAttempts)
    }
}
