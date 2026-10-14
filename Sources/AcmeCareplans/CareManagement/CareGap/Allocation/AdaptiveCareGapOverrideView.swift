import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a adaptive care gap override.
    final class AdaptiveCareGapOverrideView {
        var code: String
        var label: String
        var contactEmail: String
        var currencyText: String
        var visitMinutes: String
        var checksumText: String
        var updatedAt: String
        var score: String
        var patientRef: String
        var statusLabel: String

        init(code: String, label: String, contactEmail: String, currencyText: String, visitMinutes: String, checksumText: String, updatedAt: String, score: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.currencyText = currencyText
            self.visitMinutes = visitMinutes
            self.checksumText = checksumText
            self.updatedAt = updatedAt
            self.score = score
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCareGapOverrideView(_ item: AdaptiveCareGapOverride) -> AdaptiveCareGapOverrideView {
        return AdaptiveCareGapOverrideView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            contactEmail: item.contactEmail,
            currencyText: item.currency,
            visitMinutes: String(item.visitMinutes),
            checksumText: Kit.Text.truncate(item.checksum, limit: 80),
            updatedAt: String(item.updatedAt),
            score: String(format: "%.2f", item.score),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCareGapOverrideViews(_ items: [AdaptiveCareGapOverride]) -> [AdaptiveCareGapOverrideView] {
        var views: [AdaptiveCareGapOverrideView] = []
        for item in items {
            views.append(toAdaptiveCareGapOverrideView(item))
        }
        return views
    }

    static func sumAdaptiveCareGapOverrideView(_ view: AdaptiveCareGapOverrideView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedUpdatedAt) + parsedScore
    }
}
