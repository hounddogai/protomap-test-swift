import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending study baseline.
    final class PendingStudyBaselineView {
        var code: String
        var title: String
        var minimum: String
        var revisionText: String
        var acuityText: String
        var rate: String
        var wardText: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, title: String, minimum: String, revisionText: String, acuityText: String, rate: String, wardText: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.revisionText = revisionText
            self.acuityText = acuityText
            self.rate = rate
            self.wardText = wardText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toPendingStudyBaselineView(_ item: PendingStudyBaseline) -> PendingStudyBaselineView {
        return PendingStudyBaselineView(
            code: item.code,
            title: item.title,
            minimum: String(format: "%.2f", item.minimum),
            revisionText: String(item.revision),
            acuityText: String(item.acuity),
            rate: String(format: "%.2f", item.rate),
            wardText: item.ward,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingStudyBaselineViews(_ items: [PendingStudyBaseline]) -> [PendingStudyBaselineView] {
        var views: [PendingStudyBaselineView] = []
        for item in items {
            views.append(toPendingStudyBaselineView(item))
        }
        return views
    }

    static func sumPendingStudyBaselineView(_ view: PendingStudyBaselineView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedMinimum + Double(parsedRevision) + Double(parsedAcuity)
    }
}
