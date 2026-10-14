import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a scheduled formulary milestone.
    final class ScheduledFormularyMilestoneView {
        var code: String
        var title: String
        var ratioText: String
        var patientRef: String
        var procedureCodeText: String
        var createdAt: String
        var acuity: String
        var statusLabel: String

        init(code: String, title: String, ratioText: String, patientRef: String, procedureCodeText: String, createdAt: String, acuity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ratioText = ratioText
            self.patientRef = patientRef
            self.procedureCodeText = procedureCodeText
            self.createdAt = createdAt
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledFormularyMilestoneView(_ item: ScheduledFormularyMilestone) -> ScheduledFormularyMilestoneView {
        return ScheduledFormularyMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            ratioText: String(format: "%.2f", item.ratio),
            patientRef: item.patientRef,
            procedureCodeText: item.procedureCode,
            createdAt: String(item.createdAt),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledFormularyMilestoneViews(_ items: [ScheduledFormularyMilestone]) -> [ScheduledFormularyMilestoneView] {
        var views: [ScheduledFormularyMilestoneView] = []
        for item in items {
            views.append(toScheduledFormularyMilestoneView(item))
        }
        return views
    }

    static func sumScheduledFormularyMilestoneView(_ view: ScheduledFormularyMilestoneView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedRatio + Double(parsedCreatedAt) + Double(parsedAcuity)
    }
}
