import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation plan.
    final class IsolationPlanView {
        var code: String
        var label: String
        var pinned: String
        var limit: String
        var encounterID: String
        var refills: String
        var expiresAtText: String
        var summaryText: String
        var visible: String
        var startsAt: String
        var statusLabel: String

        init(code: String, label: String, pinned: String, limit: String, encounterID: String, refills: String, expiresAtText: String, summaryText: String, visible: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.limit = limit
            self.encounterID = encounterID
            self.refills = refills
            self.expiresAtText = expiresAtText
            self.summaryText = summaryText
            self.visible = visible
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationPlanView(_ item: IsolationPlan) -> IsolationPlanView {
        return IsolationPlanView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            pinned: "\(item.pinned)",
            limit: String(item.limit),
            encounterID: item.encounterID,
            refills: String(item.refills),
            expiresAtText: String(item.expiresAt),
            summaryText: item.summary,
            visible: "\(item.visible)",
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationPlanViews(_ items: [IsolationPlan]) -> [IsolationPlanView] {
        var views: [IsolationPlanView] = []
        for item in items {
            views.append(toIsolationPlanView(item))
        }
        return views
    }

    static func sumIsolationPlanView(_ view: IsolationPlanView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedLimit) + Double(parsedRefills) + Double(parsedExpiresAt)
    }
}
