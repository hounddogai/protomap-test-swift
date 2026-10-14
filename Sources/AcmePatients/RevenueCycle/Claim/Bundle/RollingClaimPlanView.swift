import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling claim plan.
    final class RollingClaimPlanView {
        var code: String
        var title: String
        var patientRef: String
        var pinnedText: String
        var sequenceText: String
        var statusLabel: String

        init(code: String, title: String, patientRef: String, pinnedText: String, sequenceText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.pinnedText = pinnedText
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingClaimPlanView(_ item: RollingClaimPlan) -> RollingClaimPlanView {
        return RollingClaimPlanView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            pinnedText: "\(item.pinned)",
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingClaimPlanViews(_ items: [RollingClaimPlan]) -> [RollingClaimPlanView] {
        var views: [RollingClaimPlanView] = []
        for item in items {
            views.append(toRollingClaimPlanView(item))
        }
        return views
    }

    static func sumRollingClaimPlanView(_ view: RollingClaimPlanView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedSequence)
    }
}
