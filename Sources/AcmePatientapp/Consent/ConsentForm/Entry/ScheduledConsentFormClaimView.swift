import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled consent form claim.
    final class ScheduledConsentFormClaimView {
        var code: String
        var titleText: String
        var minimumText: String
        var reviewer: String
        var diagnosisCodeText: String
        var pinned: String
        var nameText: String
        var copay: String
        var encounterIDText: String
        var startsAt: String
        var quantityText: String
        var statusLabel: String

        init(code: String, titleText: String, minimumText: String, reviewer: String, diagnosisCodeText: String, pinned: String, nameText: String, copay: String, encounterIDText: String, startsAt: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.minimumText = minimumText
            self.reviewer = reviewer
            self.diagnosisCodeText = diagnosisCodeText
            self.pinned = pinned
            self.nameText = nameText
            self.copay = copay
            self.encounterIDText = encounterIDText
            self.startsAt = startsAt
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledConsentFormClaimView(_ item: ScheduledConsentFormClaim) -> ScheduledConsentFormClaimView {
        return ScheduledConsentFormClaimView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: Kit.Text.truncate(item.title, limit: 80),
            minimumText: String(format: "%.2f", item.minimum),
            reviewer: item.reviewer,
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            pinned: "\(item.pinned)",
            nameText: item.name,
            copay: String(format: "%.2f", item.copay),
            encounterIDText: item.encounterID,
            startsAt: String(item.startsAt),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledConsentFormClaimViews(_ items: [ScheduledConsentFormClaim]) -> [ScheduledConsentFormClaimView] {
        var views: [ScheduledConsentFormClaimView] = []
        for item in items {
            views.append(toScheduledConsentFormClaimView(item))
        }
        return views
    }

    static func sumScheduledConsentFormClaimView(_ view: ScheduledConsentFormClaimView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedMinimum + parsedCopay + Double(parsedStartsAt)
    }
}
