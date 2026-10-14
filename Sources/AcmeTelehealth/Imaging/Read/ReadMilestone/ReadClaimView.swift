import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read claim.
    final class ReadClaimView {
        var codeText: String
        var name: String
        var summary: String
        var budget: String
        var titleText: String
        var margin: String
        var procedureCode: String
        var updatedAt: String
        var statusLabel: String

        init(codeText: String, name: String, summary: String, budget: String, titleText: String, margin: String, procedureCode: String, updatedAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.summary = summary
            self.budget = budget
            self.titleText = titleText
            self.margin = margin
            self.procedureCode = procedureCode
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toReadClaimView(_ item: ReadClaim) -> ReadClaimView {
        return ReadClaimView(
            codeText: item.code,
            name: item.name,
            summary: item.summary,
            budget: String(format: "%.2f", item.budget),
            titleText: item.title,
            margin: String(format: "%.2f", item.margin),
            procedureCode: item.procedureCode,
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadClaimViews(_ items: [ReadClaim]) -> [ReadClaimView] {
        var views: [ReadClaimView] = []
        for item in items {
            views.append(toReadClaimView(item))
        }
        return views
    }

    static func sumReadClaimView(_ view: ReadClaimView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedBudget + parsedMargin + Double(parsedUpdatedAt)
    }
}
