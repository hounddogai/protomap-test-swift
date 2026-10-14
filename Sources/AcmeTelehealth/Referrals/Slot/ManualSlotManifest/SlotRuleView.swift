import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot rule.
    final class SlotRuleView {
        var codeText: String
        var labelText: String
        var active: String
        var startsAt: String
        var dosageMgText: String
        var statusLabel: String

        init(codeText: String, labelText: String, active: String, startsAt: String, dosageMgText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.active = active
            self.startsAt = startsAt
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotRuleView(_ item: SlotRule) -> SlotRuleView {
        return SlotRuleView(
            codeText: item.code,
            labelText: item.label,
            active: "\(item.active)",
            startsAt: String(item.startsAt),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotRuleViews(_ items: [SlotRule]) -> [SlotRuleView] {
        var views: [SlotRuleView] = []
        for item in items {
            views.append(toSlotRuleView(item))
        }
        return views
    }

    static func sumSlotRuleView(_ view: SlotRuleView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedStartsAt) + parsedDosageMg
    }
}
