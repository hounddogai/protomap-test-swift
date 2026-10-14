import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority audit.
    final class PriorityAuditView {
        var code: String
        var label: String
        var visitMinutes: String
        var graceDays: String
        var ceilingText: String
        var diagnosisCode: String
        var ratio: String
        var refills: String
        var facility: String
        var statusLabel: String

        init(code: String, label: String, visitMinutes: String, graceDays: String, ceilingText: String, diagnosisCode: String, ratio: String, refills: String, facility: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.graceDays = graceDays
            self.ceilingText = ceilingText
            self.diagnosisCode = diagnosisCode
            self.ratio = ratio
            self.refills = refills
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityAuditView(_ item: PriorityAudit) -> PriorityAuditView {
        return PriorityAuditView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            visitMinutes: String(item.visitMinutes),
            graceDays: String(item.graceDays),
            ceilingText: String(format: "%.2f", item.ceiling),
            diagnosisCode: item.diagnosisCode,
            ratio: String(format: "%.2f", item.ratio),
            refills: String(item.refills),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityAuditViews(_ items: [PriorityAudit]) -> [PriorityAuditView] {
        var views: [PriorityAuditView] = []
        for item in items {
            views.append(toPriorityAuditView(item))
        }
        return views
    }

    static func sumPriorityAuditView(_ view: PriorityAuditView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedGraceDays) + parsedCeiling
    }
}
