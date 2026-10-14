import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a global read estimate.
    final class GlobalReadEstimateView {
        var code: String
        var label: String
        var visible: String
        var revisionText: String
        var discount: String
        var procedureCodeText: String
        var visitMinutes: String
        var amount: String
        var statusLabel: String

        init(code: String, label: String, visible: String, revisionText: String, discount: String, procedureCodeText: String, visitMinutes: String, amount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visible = visible
            self.revisionText = revisionText
            self.discount = discount
            self.procedureCodeText = procedureCodeText
            self.visitMinutes = visitMinutes
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalReadEstimateView(_ item: GlobalReadEstimate) -> GlobalReadEstimateView {
        return GlobalReadEstimateView(
            code: item.code,
            label: item.label,
            visible: "\(item.visible)",
            revisionText: String(item.revision),
            discount: String(format: "%.2f", item.discount),
            procedureCodeText: item.procedureCode,
            visitMinutes: String(item.visitMinutes),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalReadEstimateViews(_ items: [GlobalReadEstimate]) -> [GlobalReadEstimateView] {
        var views: [GlobalReadEstimateView] = []
        for item in items {
            views.append(toGlobalReadEstimateView(item))
        }
        return views
    }

    static func sumGlobalReadEstimateView(_ view: GlobalReadEstimateView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedRevision) + parsedDiscount + Double(parsedVisitMinutes)
    }
}
