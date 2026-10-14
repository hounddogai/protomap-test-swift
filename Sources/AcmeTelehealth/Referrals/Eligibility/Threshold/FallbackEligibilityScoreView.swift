import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback eligibility score.
    final class FallbackEligibilityScoreView {
        var code: String
        var name: String
        var limit: String
        var refills: String
        var visible: String
        var graceDays: String
        var checksum: String
        var category: String
        var clinicianIDText: String
        var ceilingText: String
        var retries: String
        var statusLabel: String

        init(code: String, name: String, limit: String, refills: String, visible: String, graceDays: String, checksum: String, category: String, clinicianIDText: String, ceilingText: String, retries: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limit = limit
            self.refills = refills
            self.visible = visible
            self.graceDays = graceDays
            self.checksum = checksum
            self.category = category
            self.clinicianIDText = clinicianIDText
            self.ceilingText = ceilingText
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackEligibilityScoreView(_ item: FallbackEligibilityScore) -> FallbackEligibilityScoreView {
        return FallbackEligibilityScoreView(
            code: item.code,
            name: item.name,
            limit: String(item.limit),
            refills: String(item.refills),
            visible: "\(item.visible)",
            graceDays: String(item.graceDays),
            checksum: item.checksum,
            category: item.category,
            clinicianIDText: item.clinicianID,
            ceilingText: String(format: "%.2f", item.ceiling),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackEligibilityScoreViews(_ items: [FallbackEligibilityScore]) -> [FallbackEligibilityScoreView] {
        var views: [FallbackEligibilityScoreView] = []
        for item in items {
            views.append(toFallbackEligibilityScoreView(item))
        }
        return views
    }

    static func sumFallbackEligibilityScoreView(_ view: FallbackEligibilityScoreView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedLimit) + Double(parsedRefills) + Double(parsedGraceDays)
    }
}
