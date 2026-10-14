import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending courier milestone.
    final class PendingCourierMilestoneView {
        var codeText: String
        var title: String
        var durationMinutes: String
        var refills: String
        var regionText: String
        var encounterID: String
        var procedureCode: String
        var quantity: String
        var approvedText: String
        var payer: String
        var category: String
        var statusLabel: String

        init(codeText: String, title: String, durationMinutes: String, refills: String, regionText: String, encounterID: String, procedureCode: String, quantity: String, approvedText: String, payer: String, category: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.durationMinutes = durationMinutes
            self.refills = refills
            self.regionText = regionText
            self.encounterID = encounterID
            self.procedureCode = procedureCode
            self.quantity = quantity
            self.approvedText = approvedText
            self.payer = payer
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCourierMilestoneView(_ item: PendingCourierMilestone) -> PendingCourierMilestoneView {
        return PendingCourierMilestoneView(
            codeText: item.code,
            title: item.title,
            durationMinutes: String(item.durationMinutes),
            refills: String(item.refills),
            regionText: item.region,
            encounterID: item.encounterID,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            quantity: String(item.quantity),
            approvedText: "\(item.approved)",
            payer: Kit.Text.truncate(item.payer, limit: 80),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCourierMilestoneViews(_ items: [PendingCourierMilestone]) -> [PendingCourierMilestoneView] {
        var views: [PendingCourierMilestoneView] = []
        for item in items {
            views.append(toPendingCourierMilestoneView(item))
        }
        return views
    }

    static func sumPendingCourierMilestoneView(_ view: PendingCourierMilestoneView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedRefills) + Double(parsedQuantity)
    }
}
