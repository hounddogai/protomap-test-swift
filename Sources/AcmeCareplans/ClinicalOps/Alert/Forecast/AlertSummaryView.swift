import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert summary.
    final class AlertSummaryView {
        var codeText: String
        var label: String
        var archivedText: String
        var endsAtText: String
        var externalRef: String
        var ownerID: String
        var region: String
        var statusLabel: String

        init(codeText: String, label: String, archivedText: String, endsAtText: String, externalRef: String, ownerID: String, region: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.archivedText = archivedText
            self.endsAtText = endsAtText
            self.externalRef = externalRef
            self.ownerID = ownerID
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toAlertSummaryView(_ item: AlertSummary) -> AlertSummaryView {
        return AlertSummaryView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            archivedText: "\(item.archived)",
            endsAtText: String(item.endsAt),
            externalRef: item.externalRef,
            ownerID: item.ownerID,
            region: Kit.Text.truncate(item.region, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertSummaryViews(_ items: [AlertSummary]) -> [AlertSummaryView] {
        var views: [AlertSummaryView] = []
        for item in items {
            views.append(toAlertSummaryView(item))
        }
        return views
    }

    static func sumAlertSummaryView(_ view: AlertSummaryView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
