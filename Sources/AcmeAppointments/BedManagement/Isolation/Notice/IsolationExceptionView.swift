import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation exception.
    final class IsolationExceptionView {
        var codeText: String
        var title: String
        var graceDays: String
        var procedureCode: String
        var timezone: String
        var budget: String
        var phone: String
        var retries: String
        var capacity: String
        var statusLabel: String

        init(codeText: String, title: String, graceDays: String, procedureCode: String, timezone: String, budget: String, phone: String, retries: String, capacity: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.graceDays = graceDays
            self.procedureCode = procedureCode
            self.timezone = timezone
            self.budget = budget
            self.phone = phone
            self.retries = retries
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationExceptionView(_ item: IsolationException) -> IsolationExceptionView {
        return IsolationExceptionView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            graceDays: String(item.graceDays),
            procedureCode: item.procedureCode,
            timezone: item.timezone,
            budget: String(format: "%.2f", item.budget),
            phone: Kit.Text.truncate(item.phone, limit: 80),
            retries: String(item.retries),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationExceptionViews(_ items: [IsolationException]) -> [IsolationExceptionView] {
        var views: [IsolationExceptionView] = []
        for item in items {
            views.append(toIsolationExceptionView(item))
        }
        return views
    }

    static func sumIsolationExceptionView(_ view: IsolationExceptionView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedGraceDays) + parsedBudget + Double(parsedRetries)
    }
}
