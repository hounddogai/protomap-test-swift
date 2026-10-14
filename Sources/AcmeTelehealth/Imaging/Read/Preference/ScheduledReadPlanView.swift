import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a scheduled read plan.
    final class ScheduledReadPlanView {
        var code: String
        var title: String
        var procedureCodeText: String
        var minimumText: String
        var visitMinutes: String
        var visible: String
        var archived: String
        var quantity: String
        var bedText: String
        var statusLabel: String

        init(code: String, title: String, procedureCodeText: String, minimumText: String, visitMinutes: String, visible: String, archived: String, quantity: String, bedText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCodeText = procedureCodeText
            self.minimumText = minimumText
            self.visitMinutes = visitMinutes
            self.visible = visible
            self.archived = archived
            self.quantity = quantity
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledReadPlanView(_ item: ScheduledReadPlan) -> ScheduledReadPlanView {
        return ScheduledReadPlanView(
            code: item.code,
            title: item.title,
            procedureCodeText: item.procedureCode,
            minimumText: String(format: "%.2f", item.minimum),
            visitMinutes: String(item.visitMinutes),
            visible: "\(item.visible)",
            archived: "\(item.archived)",
            quantity: String(item.quantity),
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledReadPlanViews(_ items: [ScheduledReadPlan]) -> [ScheduledReadPlanView] {
        var views: [ScheduledReadPlanView] = []
        for item in items {
            views.append(toScheduledReadPlanView(item))
        }
        return views
    }

    static func sumScheduledReadPlanView(_ view: ScheduledReadPlanView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedMinimum + Double(parsedVisitMinutes) + Double(parsedQuantity)
    }
}
