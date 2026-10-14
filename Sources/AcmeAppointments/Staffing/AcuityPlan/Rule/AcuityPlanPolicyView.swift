import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan policy.
    final class AcuityPlanPolicyView {
        var code: String
        var label: String
        var summary: String
        var bed: String
        var timezone: String
        var notes: String
        var specialty: String
        var ratio: String
        var statusLabel: String

        init(code: String, label: String, summary: String, bed: String, timezone: String, notes: String, specialty: String, ratio: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.summary = summary
            self.bed = bed
            self.timezone = timezone
            self.notes = notes
            self.specialty = specialty
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanPolicyView(_ item: AcuityPlanPolicy) -> AcuityPlanPolicyView {
        return AcuityPlanPolicyView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            summary: item.summary,
            bed: Kit.Text.truncate(item.bed, limit: 64),
            timezone: item.timezone,
            notes: item.notes,
            specialty: Kit.Text.truncate(item.specialty, limit: 80),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanPolicyViews(_ items: [AcuityPlanPolicy]) -> [AcuityPlanPolicyView] {
        var views: [AcuityPlanPolicyView] = []
        for item in items {
            views.append(toAcuityPlanPolicyView(item))
        }
        return views
    }

    static func sumAcuityPlanPolicyView(_ view: AcuityPlanPolicyView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
