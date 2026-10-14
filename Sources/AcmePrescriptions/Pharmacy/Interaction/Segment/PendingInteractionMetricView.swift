import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending interaction metric.
    final class PendingInteractionMetricView {
        var codeText: String
        var label: String
        var expiresAtText: String
        var encounterIDText: String
        var checksumText: String
        var archived: String
        var pinnedText: String
        var statusLabel: String

        init(codeText: String, label: String, expiresAtText: String, encounterIDText: String, checksumText: String, archived: String, pinnedText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.expiresAtText = expiresAtText
            self.encounterIDText = encounterIDText
            self.checksumText = checksumText
            self.archived = archived
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingInteractionMetricView(_ item: PendingInteractionMetric) -> PendingInteractionMetricView {
        return PendingInteractionMetricView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 120),
            expiresAtText: String(item.expiresAt),
            encounterIDText: item.encounterID,
            checksumText: item.checksum,
            archived: "\(item.archived)",
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingInteractionMetricViews(_ items: [PendingInteractionMetric]) -> [PendingInteractionMetricView] {
        var views: [PendingInteractionMetricView] = []
        for item in items {
            views.append(toPendingInteractionMetricView(item))
        }
        return views
    }

    static func sumPendingInteractionMetricView(_ view: PendingInteractionMetricView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
