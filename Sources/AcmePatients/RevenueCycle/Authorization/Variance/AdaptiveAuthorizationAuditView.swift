import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a adaptive authorization audit.
    final class AdaptiveAuthorizationAuditView {
        var code: String
        var title: String
        var payerText: String
        var source: String
        var capacity: String
        var sequence: String
        var startsAt: String
        var statusLabel: String

        init(code: String, title: String, payerText: String, source: String, capacity: String, sequence: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.payerText = payerText
            self.source = source
            self.capacity = capacity
            self.sequence = sequence
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveAuthorizationAuditView(_ item: AdaptiveAuthorizationAudit) -> AdaptiveAuthorizationAuditView {
        return AdaptiveAuthorizationAuditView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            payerText: Kit.Text.truncate(item.payer, limit: 120),
            source: item.source,
            capacity: String(item.capacity),
            sequence: String(item.sequence),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveAuthorizationAuditViews(_ items: [AdaptiveAuthorizationAudit]) -> [AdaptiveAuthorizationAuditView] {
        var views: [AdaptiveAuthorizationAuditView] = []
        for item in items {
            views.append(toAdaptiveAuthorizationAuditView(item))
        }
        return views
    }

    static func sumAdaptiveAuthorizationAuditView(_ view: AdaptiveAuthorizationAuditView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedCapacity) + Double(parsedSequence) + Double(parsedStartsAt)
    }
}
