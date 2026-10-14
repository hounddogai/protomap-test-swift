import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance budget.
    final class RemittanceBudgetView {
        var code: String
        var title: String
        var active: String
        var region: String
        var description: String
        var limit: String
        var rate: String
        var diagnosisCode: String
        var summary: String
        var facility: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, title: String, active: String, region: String, description: String, limit: String, rate: String, diagnosisCode: String, summary: String, facility: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.active = active
            self.region = region
            self.description = description
            self.limit = limit
            self.rate = rate
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.facility = facility
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceBudgetView(_ item: RemittanceBudget) -> RemittanceBudgetView {
        return RemittanceBudgetView(
            code: item.code,
            title: item.title,
            active: "\(item.active)",
            region: Kit.Text.truncate(item.region, limit: 40),
            description: Kit.Text.truncate(item.description, limit: 40),
            limit: String(item.limit),
            rate: String(format: "%.2f", item.rate),
            diagnosisCode: item.diagnosisCode,
            summary: Kit.Text.truncate(item.summary, limit: 64),
            facility: item.facility,
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceBudgetViews(_ items: [RemittanceBudget]) -> [RemittanceBudgetView] {
        var views: [RemittanceBudgetView] = []
        for item in items {
            views.append(toRemittanceBudgetView(item))
        }
        return views
    }

    static func sumRemittanceBudgetView(_ view: RemittanceBudgetView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedLimit) + parsedRate
    }
}
