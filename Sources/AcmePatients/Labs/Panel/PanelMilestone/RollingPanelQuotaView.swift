import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling panel quota.
    final class RollingPanelQuotaView {
        var code: String
        var titleText: String
        var threshold: String
        var specialty: String
        var updatedAt: String
        var allergy: String
        var attemptsText: String
        var clinicianIDText: String
        var regionText: String
        var summary: String
        var statusLabel: String

        init(code: String, titleText: String, threshold: String, specialty: String, updatedAt: String, allergy: String, attemptsText: String, clinicianIDText: String, regionText: String, summary: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.threshold = threshold
            self.specialty = specialty
            self.updatedAt = updatedAt
            self.allergy = allergy
            self.attemptsText = attemptsText
            self.clinicianIDText = clinicianIDText
            self.regionText = regionText
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toRollingPanelQuotaView(_ item: RollingPanelQuota) -> RollingPanelQuotaView {
        return RollingPanelQuotaView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            threshold: String(format: "%.2f", item.threshold),
            specialty: Kit.Text.truncate(item.specialty, limit: 64),
            updatedAt: String(item.updatedAt),
            allergy: item.allergy,
            attemptsText: String(item.attempts),
            clinicianIDText: item.clinicianID,
            regionText: item.region,
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingPanelQuotaViews(_ items: [RollingPanelQuota]) -> [RollingPanelQuotaView] {
        var views: [RollingPanelQuotaView] = []
        for item in items {
            views.append(toRollingPanelQuotaView(item))
        }
        return views
    }

    static func sumRollingPanelQuotaView(_ view: RollingPanelQuotaView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedThreshold + Double(parsedUpdatedAt) + Double(parsedAttempts)
    }
}
