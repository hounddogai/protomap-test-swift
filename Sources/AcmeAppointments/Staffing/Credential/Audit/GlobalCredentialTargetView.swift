import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global credential target.
    final class GlobalCredentialTargetView {
        var codeText: String
        var nameText: String
        var updatedAt: String
        var budget: String
        var retries: String
        var currency: String
        var windowDaysText: String
        var scoreText: String
        var discount: String
        var diagnosisCode: String
        var statusLabel: String

        init(codeText: String, nameText: String, updatedAt: String, budget: String, retries: String, currency: String, windowDaysText: String, scoreText: String, discount: String, diagnosisCode: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.updatedAt = updatedAt
            self.budget = budget
            self.retries = retries
            self.currency = currency
            self.windowDaysText = windowDaysText
            self.scoreText = scoreText
            self.discount = discount
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCredentialTargetView(_ item: GlobalCredentialTarget) -> GlobalCredentialTargetView {
        return GlobalCredentialTargetView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            updatedAt: String(item.updatedAt),
            budget: String(format: "%.2f", item.budget),
            retries: String(item.retries),
            currency: item.currency,
            windowDaysText: String(item.windowDays),
            scoreText: String(format: "%.2f", item.score),
            discount: String(format: "%.2f", item.discount),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCredentialTargetViews(_ items: [GlobalCredentialTarget]) -> [GlobalCredentialTargetView] {
        var views: [GlobalCredentialTargetView] = []
        for item in items {
            views.append(toGlobalCredentialTargetView(item))
        }
        return views
    }

    static func sumGlobalCredentialTargetView(_ view: GlobalCredentialTargetView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedUpdatedAt) + parsedBudget + Double(parsedRetries)
    }
}
