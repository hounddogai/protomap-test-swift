import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority rollup.
    final class PriorityRollupView {
        var code: String
        var name: String
        var approved: String
        var acuity: String
        var timezoneText: String
        var statusLabel: String

        init(code: String, name: String, approved: String, acuity: String, timezoneText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.approved = approved
            self.acuity = acuity
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityRollupView(_ item: PriorityRollup) -> PriorityRollupView {
        return PriorityRollupView(
            code: item.code,
            name: item.name,
            approved: "\(item.approved)",
            acuity: String(item.acuity),
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityRollupViews(_ items: [PriorityRollup]) -> [PriorityRollupView] {
        var views: [PriorityRollupView] = []
        for item in items {
            views.append(toPriorityRollupView(item))
        }
        return views
    }

    static func sumPriorityRollupView(_ view: PriorityRollupView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
