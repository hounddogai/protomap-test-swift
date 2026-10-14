import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a global interaction baseline.
    final class GlobalInteractionBaselineView {
        var codeText: String
        var label: String
        var timezoneText: String
        var procedureCode: String
        var budget: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, timezoneText: String, procedureCode: String, budget: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.timezoneText = timezoneText
            self.procedureCode = procedureCode
            self.budget = budget
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalInteractionBaselineView(_ item: GlobalInteractionBaseline) -> GlobalInteractionBaselineView {
        return GlobalInteractionBaselineView(
            codeText: item.code,
            label: item.label,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 80),
            procedureCode: item.procedureCode,
            budget: String(format: "%.2f", item.budget),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalInteractionBaselineViews(_ items: [GlobalInteractionBaseline]) -> [GlobalInteractionBaselineView] {
        var views: [GlobalInteractionBaselineView] = []
        for item in items {
            views.append(toGlobalInteractionBaselineView(item))
        }
        return views
    }

    static func sumGlobalInteractionBaselineView(_ view: GlobalInteractionBaselineView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedBudget + Double(parsedVisitMinutes)
    }
}
