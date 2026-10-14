import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance notice.
    final class RemittanceNoticeView {
        var code: String
        var title: String
        var notesText: String
        var endsAt: String
        var reviewer: String
        var active: String
        var costText: String
        var facility: String
        var archived: String
        var visible: String
        var statusLabel: String

        init(code: String, title: String, notesText: String, endsAt: String, reviewer: String, active: String, costText: String, facility: String, archived: String, visible: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.notesText = notesText
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.active = active
            self.costText = costText
            self.facility = facility
            self.archived = archived
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceNoticeView(_ item: RemittanceNotice) -> RemittanceNoticeView {
        return RemittanceNoticeView(
            code: item.code,
            title: item.title,
            notesText: item.notes,
            endsAt: String(item.endsAt),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            active: "\(item.active)",
            costText: String(format: "%.2f", item.cost),
            facility: item.facility,
            archived: "\(item.archived)",
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceNoticeViews(_ items: [RemittanceNotice]) -> [RemittanceNoticeView] {
        var views: [RemittanceNoticeView] = []
        for item in items {
            views.append(toRemittanceNoticeView(item))
        }
        return views
    }

    static func sumRemittanceNoticeView(_ view: RemittanceNoticeView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedEndsAt) + parsedCost
    }
}
