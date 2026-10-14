import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling priority agreement.
    final class RollingPriorityAgreementView {
        var code: String
        var title: String
        var procedureCode: String
        var acuity: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, title: String, procedureCode: String, acuity: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.acuity = acuity
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toRollingPriorityAgreementView(_ item: RollingPriorityAgreement) -> RollingPriorityAgreementView {
        return RollingPriorityAgreementView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            procedureCode: item.procedureCode,
            acuity: String(item.acuity),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingPriorityAgreementViews(_ items: [RollingPriorityAgreement]) -> [RollingPriorityAgreementView] {
        var views: [RollingPriorityAgreementView] = []
        for item in items {
            views.append(toRollingPriorityAgreementView(item))
        }
        return views
    }

    static func sumRollingPriorityAgreementView(_ view: RollingPriorityAgreementView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedAcuity) + Double(parsedVisitMinutes)
    }
}
