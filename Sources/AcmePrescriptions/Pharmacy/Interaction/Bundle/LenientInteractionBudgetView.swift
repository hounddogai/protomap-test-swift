import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient interaction budget.
    final class LenientInteractionBudgetView {
        var code: String
        var name: String
        var retries: String
        var dosageMg: String
        var segment: String
        var clinicianID: String
        var copayText: String
        var unit: String
        var ownerID: String
        var active: String
        var statusLabel: String

        init(code: String, name: String, retries: String, dosageMg: String, segment: String, clinicianID: String, copayText: String, unit: String, ownerID: String, active: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.retries = retries
            self.dosageMg = dosageMg
            self.segment = segment
            self.clinicianID = clinicianID
            self.copayText = copayText
            self.unit = unit
            self.ownerID = ownerID
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toLenientInteractionBudgetView(_ item: LenientInteractionBudget) -> LenientInteractionBudgetView {
        return LenientInteractionBudgetView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 64),
            retries: String(item.retries),
            dosageMg: String(format: "%.2f", item.dosageMg),
            segment: item.segment,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            copayText: String(format: "%.2f", item.copay),
            unit: item.unit,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientInteractionBudgetViews(_ items: [LenientInteractionBudget]) -> [LenientInteractionBudgetView] {
        var views: [LenientInteractionBudgetView] = []
        for item in items {
            views.append(toLenientInteractionBudgetView(item))
        }
        return views
    }

    static func sumLenientInteractionBudgetView(_ view: LenientInteractionBudgetView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedRetries) + parsedDosageMg + parsedCopay
    }
}
