import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a global claim agreement.
    final class GlobalClaimAgreementView {
        var code: String
        var name: String
        var source: String
        var scoreText: String
        var encounterID: String
        var weight: String
        var checksum: String
        var timezone: String
        var statusLabel: String

        init(code: String, name: String, source: String, scoreText: String, encounterID: String, weight: String, checksum: String, timezone: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.source = source
            self.scoreText = scoreText
            self.encounterID = encounterID
            self.weight = weight
            self.checksum = checksum
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalClaimAgreementView(_ item: GlobalClaimAgreement) -> GlobalClaimAgreementView {
        return GlobalClaimAgreementView(
            code: item.code,
            name: item.name,
            source: item.source,
            scoreText: String(format: "%.2f", item.score),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            weight: String(format: "%.2f", item.weight),
            checksum: item.checksum,
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalClaimAgreementViews(_ items: [GlobalClaimAgreement]) -> [GlobalClaimAgreementView] {
        var views: [GlobalClaimAgreementView] = []
        for item in items {
            views.append(toGlobalClaimAgreementView(item))
        }
        return views
    }

    static func sumGlobalClaimAgreementView(_ view: GlobalClaimAgreementView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedScore + parsedWeight
    }
}
