import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending read draft.
    final class PendingReadDraftView {
        var code: String
        var nameText: String
        var contactEmail: String
        var durationMinutesText: String
        var facility: String
        var endsAt: String
        var createdAtText: String
        var categoryText: String
        var reviewer: String
        var versionText: String
        var statusLabel: String

        init(code: String, nameText: String, contactEmail: String, durationMinutesText: String, facility: String, endsAt: String, createdAtText: String, categoryText: String, reviewer: String, versionText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.contactEmail = contactEmail
            self.durationMinutesText = durationMinutesText
            self.facility = facility
            self.endsAt = endsAt
            self.createdAtText = createdAtText
            self.categoryText = categoryText
            self.reviewer = reviewer
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingReadDraftView(_ item: PendingReadDraft) -> PendingReadDraftView {
        return PendingReadDraftView(
            code: item.code,
            nameText: item.name,
            contactEmail: item.contactEmail,
            durationMinutesText: String(item.durationMinutes),
            facility: item.facility,
            endsAt: String(item.endsAt),
            createdAtText: String(item.createdAt),
            categoryText: item.category,
            reviewer: item.reviewer,
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingReadDraftViews(_ items: [PendingReadDraft]) -> [PendingReadDraftView] {
        var views: [PendingReadDraftView] = []
        for item in items {
            views.append(toPendingReadDraftView(item))
        }
        return views
    }

    static func sumPendingReadDraftView(_ view: PendingReadDraftView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedEndsAt) + Double(parsedCreatedAt)
    }
}
