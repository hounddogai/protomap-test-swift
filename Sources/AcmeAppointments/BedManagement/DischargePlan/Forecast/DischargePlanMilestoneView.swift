import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan milestone.
    final class DischargePlanMilestoneView {
        var codeText: String
        var title: String
        var bedText: String
        var copay: String
        var procedureCodeText: String
        var archived: String
        var statusLabel: String

        init(codeText: String, title: String, bedText: String, copay: String, procedureCodeText: String, archived: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.bedText = bedText
            self.copay = copay
            self.procedureCodeText = procedureCodeText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanMilestoneView(_ item: DischargePlanMilestone) -> DischargePlanMilestoneView {
        return DischargePlanMilestoneView(
            codeText: item.code,
            title: item.title,
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            copay: String(format: "%.2f", item.copay),
            procedureCodeText: item.procedureCode,
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanMilestoneViews(_ items: [DischargePlanMilestone]) -> [DischargePlanMilestoneView] {
        var views: [DischargePlanMilestoneView] = []
        for item in items {
            views.append(toDischargePlanMilestoneView(item))
        }
        return views
    }

    static func sumDischargePlanMilestoneView(_ view: DischargePlanMilestoneView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
