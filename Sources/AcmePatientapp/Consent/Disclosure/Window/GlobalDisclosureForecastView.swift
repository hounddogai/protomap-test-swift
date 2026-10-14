import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a global disclosure forecast.
    final class GlobalDisclosureForecastView {
        var code: String
        var label: String
        var channelText: String
        var diagnosisCode: String
        var approved: String
        var procedureCode: String
        var amountText: String
        var createdAt: String
        var budgetText: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, label: String, channelText: String, diagnosisCode: String, approved: String, procedureCode: String, amountText: String, createdAt: String, budgetText: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.channelText = channelText
            self.diagnosisCode = diagnosisCode
            self.approved = approved
            self.procedureCode = procedureCode
            self.amountText = amountText
            self.createdAt = createdAt
            self.budgetText = budgetText
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalDisclosureForecastView(_ item: GlobalDisclosureForecast) -> GlobalDisclosureForecastView {
        return GlobalDisclosureForecastView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            channelText: item.channel,
            diagnosisCode: item.diagnosisCode,
            approved: "\(item.approved)",
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            amountText: String(format: "%.2f", item.amount),
            createdAt: String(item.createdAt),
            budgetText: String(format: "%.2f", item.budget),
            clinicianIDText: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalDisclosureForecastViews(_ items: [GlobalDisclosureForecast]) -> [GlobalDisclosureForecastView] {
        var views: [GlobalDisclosureForecastView] = []
        for item in items {
            views.append(toGlobalDisclosureForecastView(item))
        }
        return views
    }

    static func sumGlobalDisclosureForecastView(_ view: GlobalDisclosureForecastView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedAmount + Double(parsedCreatedAt) + parsedBudget
    }
}
