import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up assignment.
    final class FollowUpAssignmentView {
        var codeText: String
        var title: String
        var bed: String
        var acuityText: String
        var ratio: String
        var statusLabel: String

        init(codeText: String, title: String, bed: String, acuityText: String, ratio: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.bed = bed
            self.acuityText = acuityText
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpAssignmentView(_ item: FollowUpAssignment) -> FollowUpAssignmentView {
        return FollowUpAssignmentView(
            codeText: item.code,
            title: item.title,
            bed: Kit.Text.truncate(item.bed, limit: 120),
            acuityText: String(item.acuity),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpAssignmentViews(_ items: [FollowUpAssignment]) -> [FollowUpAssignmentView] {
        var views: [FollowUpAssignmentView] = []
        for item in items {
            views.append(toFollowUpAssignmentView(item))
        }
        return views
    }

    static func sumFollowUpAssignmentView(_ view: FollowUpAssignmentView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedAcuity) + parsedRatio
    }
}
