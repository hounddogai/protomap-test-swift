import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol claim.
    final class CareProtocolClaimView {
        var code: String
        var titleText: String
        var segment: String
        var country: String
        var priorityText: String
        var reviewer: String
        var statusLabel: String

        init(code: String, titleText: String, segment: String, country: String, priorityText: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.segment = segment
            self.country = country
            self.priorityText = priorityText
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolClaimView(_ item: CareProtocolClaim) -> CareProtocolClaimView {
        return CareProtocolClaimView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            segment: item.segment,
            country: item.country,
            priorityText: String(item.priority),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolClaimViews(_ items: [CareProtocolClaim]) -> [CareProtocolClaimView] {
        var views: [CareProtocolClaimView] = []
        for item in items {
            views.append(toCareProtocolClaimView(item))
        }
        return views
    }

    static func sumCareProtocolClaimView(_ view: CareProtocolClaimView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
