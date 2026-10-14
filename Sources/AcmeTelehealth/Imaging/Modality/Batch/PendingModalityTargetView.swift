import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending modality target.
    final class PendingModalityTargetView {
        var code: String
        var label: String
        var checksum: String
        var priorityText: String
        var pinned: String
        var locale: String
        var encounterID: String
        var archived: String
        var acuityText: String
        var contactEmail: String
        var summaryText: String
        var statusLabel: String

        init(code: String, label: String, checksum: String, priorityText: String, pinned: String, locale: String, encounterID: String, archived: String, acuityText: String, contactEmail: String, summaryText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.priorityText = priorityText
            self.pinned = pinned
            self.locale = locale
            self.encounterID = encounterID
            self.archived = archived
            self.acuityText = acuityText
            self.contactEmail = contactEmail
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingModalityTargetView(_ item: PendingModalityTarget) -> PendingModalityTargetView {
        return PendingModalityTargetView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            priorityText: String(item.priority),
            pinned: "\(item.pinned)",
            locale: item.locale,
            encounterID: item.encounterID,
            archived: "\(item.archived)",
            acuityText: String(item.acuity),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingModalityTargetViews(_ items: [PendingModalityTarget]) -> [PendingModalityTargetView] {
        var views: [PendingModalityTargetView] = []
        for item in items {
            views.append(toPendingModalityTargetView(item))
        }
        return views
    }

    static func sumPendingModalityTargetView(_ view: PendingModalityTargetView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedPriority) + Double(parsedAcuity)
    }
}
