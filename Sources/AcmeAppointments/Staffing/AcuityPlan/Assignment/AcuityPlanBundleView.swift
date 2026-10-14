import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan bundle.
    final class AcuityPlanBundleView {
        var code: String
        var title: String
        var acuity: String
        var segmentText: String
        var revision: String
        var statusLabel: String

        init(code: String, title: String, acuity: String, segmentText: String, revision: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.segmentText = segmentText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanBundleView(_ item: AcuityPlanBundle) -> AcuityPlanBundleView {
        return AcuityPlanBundleView(
            code: item.code,
            title: item.title,
            acuity: String(item.acuity),
            segmentText: Kit.Text.truncate(item.segment, limit: 120),
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanBundleViews(_ items: [AcuityPlanBundle]) -> [AcuityPlanBundleView] {
        var views: [AcuityPlanBundleView] = []
        for item in items {
            views.append(toAcuityPlanBundleView(item))
        }
        return views
    }

    static func sumAcuityPlanBundleView(_ view: AcuityPlanBundleView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedAcuity) + Double(parsedRevision)
    }
}
