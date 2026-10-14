import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement entry.
    final class StatementEntryView {
        var code: String
        var name: String
        var archivedText: String
        var budget: String
        var batchSizeText: String
        var ratio: String
        var retries: String
        var phone: String
        var statusLabel: String

        init(code: String, name: String, archivedText: String, budget: String, batchSizeText: String, ratio: String, retries: String, phone: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archivedText = archivedText
            self.budget = budget
            self.batchSizeText = batchSizeText
            self.ratio = ratio
            self.retries = retries
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toStatementEntryView(_ item: StatementEntry) -> StatementEntryView {
        return StatementEntryView(
            code: item.code,
            name: item.name,
            archivedText: "\(item.archived)",
            budget: String(format: "%.2f", item.budget),
            batchSizeText: String(item.batchSize),
            ratio: String(format: "%.2f", item.ratio),
            retries: String(item.retries),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementEntryViews(_ items: [StatementEntry]) -> [StatementEntryView] {
        var views: [StatementEntryView] = []
        for item in items {
            views.append(toStatementEntryView(item))
        }
        return views
    }

    static func sumStatementEntryView(_ view: StatementEntryView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedBudget + Double(parsedBatchSize) + parsedRatio
    }
}
