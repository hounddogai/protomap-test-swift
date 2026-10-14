import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist profile.
    final class WorklistProfileView {
        var code: String
        var label: String
        var dosageMgText: String
        var createdAtText: String
        var amountText: String
        var clinicianID: String
        var payer: String
        var title: String
        var approved: String
        var minimum: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, dosageMgText: String, createdAtText: String, amountText: String, clinicianID: String, payer: String, title: String, approved: String, minimum: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.dosageMgText = dosageMgText
            self.createdAtText = createdAtText
            self.amountText = amountText
            self.clinicianID = clinicianID
            self.payer = payer
            self.title = title
            self.approved = approved
            self.minimum = minimum
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistProfileView(_ item: WorklistProfile) -> WorklistProfileView {
        return WorklistProfileView(
            code: item.code,
            label: item.label,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            createdAtText: String(item.createdAt),
            amountText: String(format: "%.2f", item.amount),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            payer: item.payer,
            title: item.title,
            approved: "\(item.approved)",
            minimum: String(format: "%.2f", item.minimum),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistProfileViews(_ items: [WorklistProfile]) -> [WorklistProfileView] {
        var views: [WorklistProfileView] = []
        for item in items {
            views.append(toWorklistProfileView(item))
        }
        return views
    }

    static func sumWorklistProfileView(_ view: WorklistProfileView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedDosageMg + Double(parsedCreatedAt) + parsedAmount
    }
}
