import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a global courier milestone.
    final class GlobalCourierMilestoneView {
        var code: String
        var label: String
        var diagnosisCodeText: String
        var timezone: String
        var allergyText: String
        var sourceText: String
        var region: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCodeText: String, timezone: String, allergyText: String, sourceText: String, region: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCodeText = diagnosisCodeText
            self.timezone = timezone
            self.allergyText = allergyText
            self.sourceText = sourceText
            self.region = region
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCourierMilestoneView(_ item: GlobalCourierMilestone) -> GlobalCourierMilestoneView {
        return GlobalCourierMilestoneView(
            code: item.code,
            label: item.label,
            diagnosisCodeText: item.diagnosisCode,
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            allergyText: item.allergy,
            sourceText: item.source,
            region: Kit.Text.truncate(item.region, limit: 80),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCourierMilestoneViews(_ items: [GlobalCourierMilestone]) -> [GlobalCourierMilestoneView] {
        var views: [GlobalCourierMilestoneView] = []
        for item in items {
            views.append(toGlobalCourierMilestoneView(item))
        }
        return views
    }

    static func sumGlobalCourierMilestoneView(_ view: GlobalCourierMilestoneView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
