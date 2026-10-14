import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime plan.
    final class OvertimePlanView {
        var code: String
        var titleText: String
        var thresholdText: String
        var capacity: String
        var phoneText: String
        var statusLabel: String

        init(code: String, titleText: String, thresholdText: String, capacity: String, phoneText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.thresholdText = thresholdText
            self.capacity = capacity
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimePlanView(_ item: OvertimePlan) -> OvertimePlanView {
        return OvertimePlanView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            thresholdText: String(format: "%.2f", item.threshold),
            capacity: String(item.capacity),
            phoneText: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimePlanViews(_ items: [OvertimePlan]) -> [OvertimePlanView] {
        var views: [OvertimePlanView] = []
        for item in items {
            views.append(toOvertimePlanView(item))
        }
        return views
    }

    static func sumOvertimePlanView(_ view: OvertimePlanView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedThreshold + Double(parsedCapacity)
    }
}
