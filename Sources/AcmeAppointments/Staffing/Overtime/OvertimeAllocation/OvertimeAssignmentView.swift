import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime assignment.
    final class OvertimeAssignmentView {
        var code: String
        var name: String
        var activeText: String
        var amount: String
        var rate: String
        var statusLabel: String

        init(code: String, name: String, activeText: String, amount: String, rate: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.activeText = activeText
            self.amount = amount
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeAssignmentView(_ item: OvertimeAssignment) -> OvertimeAssignmentView {
        return OvertimeAssignmentView(
            code: item.code,
            name: item.name,
            activeText: "\(item.active)",
            amount: String(format: "%.2f", item.amount),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeAssignmentViews(_ items: [OvertimeAssignment]) -> [OvertimeAssignmentView] {
        var views: [OvertimeAssignmentView] = []
        for item in items {
            views.append(toOvertimeAssignmentView(item))
        }
        return views
    }

    static func sumOvertimeAssignmentView(_ view: OvertimeAssignmentView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedAmount + parsedRate
    }
}
