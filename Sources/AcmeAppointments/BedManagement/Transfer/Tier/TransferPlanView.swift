import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer plan.
    final class TransferPlanView {
        var codeText: String
        var title: String
        var windowDaysText: String
        var graceDays: String
        var retries: String
        var batchSize: String
        var allergy: String
        var statusLabel: String

        init(codeText: String, title: String, windowDaysText: String, graceDays: String, retries: String, batchSize: String, allergy: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.windowDaysText = windowDaysText
            self.graceDays = graceDays
            self.retries = retries
            self.batchSize = batchSize
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toTransferPlanView(_ item: TransferPlan) -> TransferPlanView {
        return TransferPlanView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            windowDaysText: String(item.windowDays),
            graceDays: String(item.graceDays),
            retries: String(item.retries),
            batchSize: String(item.batchSize),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferPlanViews(_ items: [TransferPlan]) -> [TransferPlanView] {
        var views: [TransferPlanView] = []
        for item in items {
            views.append(toTransferPlanView(item))
        }
        return views
    }

    static func sumTransferPlanView(_ view: TransferPlanView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedGraceDays) + Double(parsedRetries)
    }
}
