import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict acuity plan bundle.
    final class StrictAcuityPlanBundleView {
        var code: String
        var titleText: String
        var patientRef: String
        var externalRef: String
        var updatedAt: String
        var approvedText: String
        var ratioText: String
        var revision: String
        var unit: String
        var statusLabel: String

        init(code: String, titleText: String, patientRef: String, externalRef: String, updatedAt: String, approvedText: String, ratioText: String, revision: String, unit: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.patientRef = patientRef
            self.externalRef = externalRef
            self.updatedAt = updatedAt
            self.approvedText = approvedText
            self.ratioText = ratioText
            self.revision = revision
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toStrictAcuityPlanBundleView(_ item: StrictAcuityPlanBundle) -> StrictAcuityPlanBundleView {
        return StrictAcuityPlanBundleView(
            code: item.code,
            titleText: item.title,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 120),
            externalRef: item.externalRef,
            updatedAt: String(item.updatedAt),
            approvedText: "\(item.approved)",
            ratioText: String(format: "%.2f", item.ratio),
            revision: String(item.revision),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictAcuityPlanBundleViews(_ items: [StrictAcuityPlanBundle]) -> [StrictAcuityPlanBundleView] {
        var views: [StrictAcuityPlanBundleView] = []
        for item in items {
            views.append(toStrictAcuityPlanBundleView(item))
        }
        return views
    }

    static func sumStrictAcuityPlanBundleView(_ view: StrictAcuityPlanBundleView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedUpdatedAt) + parsedRatio + Double(parsedRevision)
    }
}
