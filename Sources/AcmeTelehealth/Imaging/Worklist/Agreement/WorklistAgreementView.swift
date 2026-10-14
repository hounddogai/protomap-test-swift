import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist agreement.
    final class WorklistAgreementView {
        var code: String
        var name: String
        var visible: String
        var updatedAt: String
        var sourceText: String
        var cost: String
        var diagnosisCode: String
        var unitText: String
        var facility: String
        var statusLabel: String

        init(code: String, name: String, visible: String, updatedAt: String, sourceText: String, cost: String, diagnosisCode: String, unitText: String, facility: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visible = visible
            self.updatedAt = updatedAt
            self.sourceText = sourceText
            self.cost = cost
            self.diagnosisCode = diagnosisCode
            self.unitText = unitText
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistAgreementView(_ item: WorklistAgreement) -> WorklistAgreementView {
        return WorklistAgreementView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            visible: "\(item.visible)",
            updatedAt: String(item.updatedAt),
            sourceText: item.source,
            cost: String(format: "%.2f", item.cost),
            diagnosisCode: item.diagnosisCode,
            unitText: item.unit,
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistAgreementViews(_ items: [WorklistAgreement]) -> [WorklistAgreementView] {
        var views: [WorklistAgreementView] = []
        for item in items {
            views.append(toWorklistAgreementView(item))
        }
        return views
    }

    static func sumWorklistAgreementView(_ view: WorklistAgreementView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedUpdatedAt) + parsedCost
    }
}
