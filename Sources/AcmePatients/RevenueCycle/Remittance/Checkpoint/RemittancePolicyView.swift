import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance policy.
    final class RemittancePolicyView {
        var code: String
        var title: String
        var allergy: String
        var durationMinutes: String
        var batchSize: String
        var archived: String
        var amount: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, title: String, allergy: String, durationMinutes: String, batchSize: String, archived: String, amount: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.durationMinutes = durationMinutes
            self.batchSize = batchSize
            self.archived = archived
            self.amount = amount
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toRemittancePolicyView(_ item: RemittancePolicy) -> RemittancePolicyView {
        return RemittancePolicyView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 80),
            allergy: item.allergy,
            durationMinutes: String(item.durationMinutes),
            batchSize: String(item.batchSize),
            archived: "\(item.archived)",
            amount: String(format: "%.2f", item.amount),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittancePolicyViews(_ items: [RemittancePolicy]) -> [RemittancePolicyView] {
        var views: [RemittancePolicyView] = []
        for item in items {
            views.append(toRemittancePolicyView(item))
        }
        return views
    }

    static func sumRemittancePolicyView(_ view: RemittancePolicyView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedBatchSize) + parsedAmount
    }
}
