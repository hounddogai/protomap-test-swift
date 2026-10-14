import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rolling care protocol profile.
    final class RollingCareProtocolProfileView {
        var codeText: String
        var title: String
        var weight: String
        var capacityText: String
        var ward: String
        var revision: String
        var timezoneText: String
        var reviewer: String
        var region: String
        var scoreText: String
        var statusLabel: String

        init(codeText: String, title: String, weight: String, capacityText: String, ward: String, revision: String, timezoneText: String, reviewer: String, region: String, scoreText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.weight = weight
            self.capacityText = capacityText
            self.ward = ward
            self.revision = revision
            self.timezoneText = timezoneText
            self.reviewer = reviewer
            self.region = region
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCareProtocolProfileView(_ item: RollingCareProtocolProfile) -> RollingCareProtocolProfileView {
        return RollingCareProtocolProfileView(
            codeText: item.code,
            title: item.title,
            weight: String(format: "%.2f", item.weight),
            capacityText: String(item.capacity),
            ward: Kit.Text.truncate(item.ward, limit: 80),
            revision: String(item.revision),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 40),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            region: Kit.Text.truncate(item.region, limit: 80),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCareProtocolProfileViews(_ items: [RollingCareProtocolProfile]) -> [RollingCareProtocolProfileView] {
        var views: [RollingCareProtocolProfileView] = []
        for item in items {
            views.append(toRollingCareProtocolProfileView(item))
        }
        return views
    }

    static func sumRollingCareProtocolProfileView(_ view: RollingCareProtocolProfileView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedWeight + Double(parsedCapacity) + Double(parsedRevision)
    }
}
