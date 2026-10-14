import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy request.
    final class ProxyRequestView {
        var codeText: String
        var title: String
        var amount: String
        var acuity: String
        var priorityText: String
        var facilityText: String
        var archived: String
        var statusLabel: String

        init(codeText: String, title: String, amount: String, acuity: String, priorityText: String, facilityText: String, archived: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.amount = amount
            self.acuity = acuity
            self.priorityText = priorityText
            self.facilityText = facilityText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toProxyRequestView(_ item: ProxyRequest) -> ProxyRequestView {
        return ProxyRequestView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            amount: String(format: "%.2f", item.amount),
            acuity: String(item.acuity),
            priorityText: String(item.priority),
            facilityText: item.facility,
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyRequestViews(_ items: [ProxyRequest]) -> [ProxyRequestView] {
        var views: [ProxyRequestView] = []
        for item in items {
            views.append(toProxyRequestView(item))
        }
        return views
    }

    static func sumProxyRequestView(_ view: ProxyRequestView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedAmount + Double(parsedAcuity) + Double(parsedPriority)
    }
}
