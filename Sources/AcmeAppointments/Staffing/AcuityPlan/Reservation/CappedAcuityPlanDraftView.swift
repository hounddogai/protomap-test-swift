import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a capped acuity plan draft.
    final class CappedAcuityPlanDraftView {
        var code: String
        var name: String
        var ownerID: String
        var channel: String
        var refills: String
        var createdAt: String
        var ceilingText: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, name: String, ownerID: String, channel: String, refills: String, createdAt: String, ceilingText: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.channel = channel
            self.refills = refills
            self.createdAt = createdAt
            self.ceilingText = ceilingText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toCappedAcuityPlanDraftView(_ item: CappedAcuityPlanDraft) -> CappedAcuityPlanDraftView {
        return CappedAcuityPlanDraftView(
            code: item.code,
            name: item.name,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            channel: item.channel,
            refills: String(item.refills),
            createdAt: String(item.createdAt),
            ceilingText: String(format: "%.2f", item.ceiling),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedAcuityPlanDraftViews(_ items: [CappedAcuityPlanDraft]) -> [CappedAcuityPlanDraftView] {
        var views: [CappedAcuityPlanDraftView] = []
        for item in items {
            views.append(toCappedAcuityPlanDraftView(item))
        }
        return views
    }

    static func sumCappedAcuityPlanDraftView(_ view: CappedAcuityPlanDraftView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedRefills) + Double(parsedCreatedAt) + parsedCeiling
    }
}
