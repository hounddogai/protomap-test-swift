import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a strict care protocol tier.
    final class StrictCareProtocolTierView {
        var codeText: String
        var title: String
        var expiresAt: String
        var batchSize: String
        var ownerID: String
        var summaryText: String
        var facility: String
        var externalRef: String
        var retries: String
        var patientRefText: String
        var label: String
        var statusLabel: String

        init(codeText: String, title: String, expiresAt: String, batchSize: String, ownerID: String, summaryText: String, facility: String, externalRef: String, retries: String, patientRefText: String, label: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.expiresAt = expiresAt
            self.batchSize = batchSize
            self.ownerID = ownerID
            self.summaryText = summaryText
            self.facility = facility
            self.externalRef = externalRef
            self.retries = retries
            self.patientRefText = patientRefText
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toStrictCareProtocolTierView(_ item: StrictCareProtocolTier) -> StrictCareProtocolTierView {
        return StrictCareProtocolTierView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            expiresAt: String(item.expiresAt),
            batchSize: String(item.batchSize),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 64),
            summaryText: item.summary,
            facility: Kit.Text.truncate(item.facility, limit: 120),
            externalRef: item.externalRef,
            retries: String(item.retries),
            patientRefText: item.patientRef,
            label: Kit.Text.truncate(item.label, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictCareProtocolTierViews(_ items: [StrictCareProtocolTier]) -> [StrictCareProtocolTierView] {
        var views: [StrictCareProtocolTierView] = []
        for item in items {
            views.append(toStrictCareProtocolTierView(item))
        }
        return views
    }

    static func sumStrictCareProtocolTierView(_ view: StrictCareProtocolTierView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedBatchSize) + Double(parsedRetries)
    }
}
