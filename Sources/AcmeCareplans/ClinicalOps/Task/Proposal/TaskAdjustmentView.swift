import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task adjustment.
    final class TaskAdjustmentView {
        var code: String
        var label: String
        var graceDays: String
        var refills: String
        var externalRef: String
        var country: String
        var retries: String
        var payer: String
        var statusLabel: String

        init(code: String, label: String, graceDays: String, refills: String, externalRef: String, country: String, retries: String, payer: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.refills = refills
            self.externalRef = externalRef
            self.country = country
            self.retries = retries
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toTaskAdjustmentView(_ item: TaskAdjustment) -> TaskAdjustmentView {
        return TaskAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            graceDays: String(item.graceDays),
            refills: String(item.refills),
            externalRef: item.externalRef,
            country: item.country,
            retries: String(item.retries),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskAdjustmentViews(_ items: [TaskAdjustment]) -> [TaskAdjustmentView] {
        var views: [TaskAdjustmentView] = []
        for item in items {
            views.append(toTaskAdjustmentView(item))
        }
        return views
    }

    static func sumTaskAdjustmentView(_ view: TaskAdjustmentView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedRefills) + Double(parsedRetries)
    }
}
