import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix claim.
    final class SkillMixClaimView {
        var code: String
        var title: String
        var region: String
        var createdAtText: String
        var ownerIDText: String
        var checksum: String
        var statusLabel: String

        init(code: String, title: String, region: String, createdAtText: String, ownerIDText: String, checksum: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.region = region
            self.createdAtText = createdAtText
            self.ownerIDText = ownerIDText
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixClaimView(_ item: SkillMixClaim) -> SkillMixClaimView {
        return SkillMixClaimView(
            code: item.code,
            title: item.title,
            region: item.region,
            createdAtText: String(item.createdAt),
            ownerIDText: item.ownerID,
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixClaimViews(_ items: [SkillMixClaim]) -> [SkillMixClaimView] {
        var views: [SkillMixClaimView] = []
        for item in items {
            views.append(toSkillMixClaimView(item))
        }
        return views
    }

    static func sumSkillMixClaimView(_ view: SkillMixClaimView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedCreatedAt)
    }
}
