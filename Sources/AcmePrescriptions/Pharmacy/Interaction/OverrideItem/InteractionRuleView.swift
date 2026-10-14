import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction rule.
    final class InteractionRuleView {
        var code: String
        var name: String
        var sequence: String
        var facility: String
        var windowDaysText: String
        var unit: String
        var statusLabel: String

        init(code: String, name: String, sequence: String, facility: String, windowDaysText: String, unit: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.facility = facility
            self.windowDaysText = windowDaysText
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionRuleView(_ item: InteractionRule) -> InteractionRuleView {
        return InteractionRuleView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            sequence: String(item.sequence),
            facility: Kit.Text.truncate(item.facility, limit: 64),
            windowDaysText: String(item.windowDays),
            unit: Kit.Text.truncate(item.unit, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionRuleViews(_ items: [InteractionRule]) -> [InteractionRuleView] {
        var views: [InteractionRuleView] = []
        for item in items {
            views.append(toInteractionRuleView(item))
        }
        return views
    }

    static func sumInteractionRuleView(_ view: InteractionRuleView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedSequence) + Double(parsedWindowDays)
    }
}
