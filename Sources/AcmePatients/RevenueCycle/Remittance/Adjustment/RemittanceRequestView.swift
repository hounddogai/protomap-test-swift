import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance request.
    final class RemittanceRequestView {
        var code: String
        var name: String
        var graceDays: String
        var region: String
        var revision: String
        var startsAtText: String
        var expiresAt: String
        var pinned: String
        var attempts: String
        var statusLabel: String

        init(code: String, name: String, graceDays: String, region: String, revision: String, startsAtText: String, expiresAt: String, pinned: String, attempts: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.region = region
            self.revision = revision
            self.startsAtText = startsAtText
            self.expiresAt = expiresAt
            self.pinned = pinned
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceRequestView(_ item: RemittanceRequest) -> RemittanceRequestView {
        return RemittanceRequestView(
            code: item.code,
            name: item.name,
            graceDays: String(item.graceDays),
            region: item.region,
            revision: String(item.revision),
            startsAtText: String(item.startsAt),
            expiresAt: String(item.expiresAt),
            pinned: "\(item.pinned)",
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceRequestViews(_ items: [RemittanceRequest]) -> [RemittanceRequestView] {
        var views: [RemittanceRequestView] = []
        for item in items {
            views.append(toRemittanceRequestView(item))
        }
        return views
    }

    static func sumRemittanceRequestView(_ view: RemittanceRequestView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedRevision) + Double(parsedStartsAt)
    }
}
