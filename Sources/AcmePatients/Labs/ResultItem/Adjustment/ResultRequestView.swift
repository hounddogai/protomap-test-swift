import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result request.
    final class ResultRequestView {
        var code: String
        var title: String
        var amount: String
        var createdAt: String
        var refills: String
        var statusLabel: String

        init(code: String, title: String, amount: String, createdAt: String, refills: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.amount = amount
            self.createdAt = createdAt
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toResultRequestView(_ item: ResultRequest) -> ResultRequestView {
        return ResultRequestView(
            code: item.code,
            title: item.title,
            amount: String(format: "%.2f", item.amount),
            createdAt: String(item.createdAt),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultRequestViews(_ items: [ResultRequest]) -> [ResultRequestView] {
        var views: [ResultRequestView] = []
        for item in items {
            views.append(toResultRequestView(item))
        }
        return views
    }

    static func sumResultRequestView(_ view: ResultRequestView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedAmount + Double(parsedCreatedAt) + Double(parsedRefills)
    }
}
