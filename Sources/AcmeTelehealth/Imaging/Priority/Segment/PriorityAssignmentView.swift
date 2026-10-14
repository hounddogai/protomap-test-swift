import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority assignment.
    final class PriorityAssignmentView {
        var codeText: String
        var label: String
        var active: String
        var ward: String
        var channel: String
        var retries: String
        var acuity: String
        var statusLabel: String

        init(codeText: String, label: String, active: String, ward: String, channel: String, retries: String, acuity: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.active = active
            self.ward = ward
            self.channel = channel
            self.retries = retries
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityAssignmentView(_ item: PriorityAssignment) -> PriorityAssignmentView {
        return PriorityAssignmentView(
            codeText: item.code,
            label: item.label,
            active: "\(item.active)",
            ward: item.ward,
            channel: Kit.Text.truncate(item.channel, limit: 120),
            retries: String(item.retries),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityAssignmentViews(_ items: [PriorityAssignment]) -> [PriorityAssignmentView] {
        var views: [PriorityAssignmentView] = []
        for item in items {
            views.append(toPriorityAssignmentView(item))
        }
        return views
    }

    static func sumPriorityAssignmentView(_ view: PriorityAssignmentView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedRetries) + Double(parsedAcuity)
    }
}
