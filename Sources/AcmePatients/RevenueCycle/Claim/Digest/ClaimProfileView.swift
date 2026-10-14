import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim profile.
    final class ClaimProfileView {
        var code: String
        var name: String
        var segment: String
        var visitMinutes: String
        var description: String
        var statusLabel: String

        init(code: String, name: String, segment: String, visitMinutes: String, description: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.segment = segment
            self.visitMinutes = visitMinutes
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toClaimProfileView(_ item: ClaimProfile) -> ClaimProfileView {
        return ClaimProfileView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            segment: Kit.Text.truncate(item.segment, limit: 120),
            visitMinutes: String(item.visitMinutes),
            description: Kit.Text.truncate(item.description, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimProfileViews(_ items: [ClaimProfile]) -> [ClaimProfileView] {
        var views: [ClaimProfileView] = []
        for item in items {
            views.append(toClaimProfileView(item))
        }
        return views
    }

    static func sumClaimProfileView(_ view: ClaimProfileView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVisitMinutes)
    }
}
