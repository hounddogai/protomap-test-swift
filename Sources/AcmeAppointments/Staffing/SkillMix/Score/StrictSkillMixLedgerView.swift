import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict skill mix ledger.
    final class StrictSkillMixLedgerView {
        var code: String
        var name: String
        var externalRef: String
        var quantityText: String
        var ratio: String
        var ownerID: String
        var region: String
        var procedureCode: String
        var priorityText: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(code: String, name: String, externalRef: String, quantityText: String, ratio: String, ownerID: String, region: String, procedureCode: String, priorityText: String, diagnosisCodeText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.quantityText = quantityText
            self.ratio = ratio
            self.ownerID = ownerID
            self.region = region
            self.procedureCode = procedureCode
            self.priorityText = priorityText
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictSkillMixLedgerView(_ item: StrictSkillMixLedger) -> StrictSkillMixLedgerView {
        return StrictSkillMixLedgerView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            externalRef: item.externalRef,
            quantityText: String(item.quantity),
            ratio: String(format: "%.2f", item.ratio),
            ownerID: item.ownerID,
            region: Kit.Text.truncate(item.region, limit: 40),
            procedureCode: item.procedureCode,
            priorityText: String(item.priority),
            diagnosisCodeText: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictSkillMixLedgerViews(_ items: [StrictSkillMixLedger]) -> [StrictSkillMixLedgerView] {
        var views: [StrictSkillMixLedgerView] = []
        for item in items {
            views.append(toStrictSkillMixLedgerView(item))
        }
        return views
    }

    static func sumStrictSkillMixLedgerView(_ view: StrictSkillMixLedgerView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedQuantity) + parsedRatio + Double(parsedPriority)
    }
}
