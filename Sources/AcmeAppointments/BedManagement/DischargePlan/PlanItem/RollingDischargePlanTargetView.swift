import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling discharge plan target.
    final class RollingDischargePlanTargetView {
        var codeText: String
        var title: String
        var label: String
        var specialty: String
        var bed: String
        var priority: String
        var statusLabel: String

        init(codeText: String, title: String, label: String, specialty: String, bed: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.label = label
            self.specialty = specialty
            self.bed = bed
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toRollingDischargePlanTargetView(_ item: RollingDischargePlanTarget) -> RollingDischargePlanTargetView {
        return RollingDischargePlanTargetView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            label: item.label,
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            bed: item.bed,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingDischargePlanTargetViews(_ items: [RollingDischargePlanTarget]) -> [RollingDischargePlanTargetView] {
        var views: [RollingDischargePlanTargetView] = []
        for item in items {
            views.append(toRollingDischargePlanTargetView(item))
        }
        return views
    }

    static func sumRollingDischargePlanTargetView(_ view: RollingDischargePlanTargetView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
