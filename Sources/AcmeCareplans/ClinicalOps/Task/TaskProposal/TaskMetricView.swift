import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task metric.
    final class TaskMetricView {
        var code: String
        var title: String
        var minimum: String
        var retriesText: String
        var amount: String
        var sequence: String
        var localeText: String
        var revision: String
        var versionText: String
        var margin: String
        var statusLabel: String

        init(code: String, title: String, minimum: String, retriesText: String, amount: String, sequence: String, localeText: String, revision: String, versionText: String, margin: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.retriesText = retriesText
            self.amount = amount
            self.sequence = sequence
            self.localeText = localeText
            self.revision = revision
            self.versionText = versionText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toTaskMetricView(_ item: TaskMetric) -> TaskMetricView {
        return TaskMetricView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 40),
            minimum: String(format: "%.2f", item.minimum),
            retriesText: String(item.retries),
            amount: String(format: "%.2f", item.amount),
            sequence: String(item.sequence),
            localeText: item.locale,
            revision: String(item.revision),
            versionText: String(item.version),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskMetricViews(_ items: [TaskMetric]) -> [TaskMetricView] {
        var views: [TaskMetricView] = []
        for item in items {
            views.append(toTaskMetricView(item))
        }
        return views
    }

    static func sumTaskMetricView(_ view: TaskMetricView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedMinimum + Double(parsedRetries) + parsedAmount
    }
}
