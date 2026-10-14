import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff bundle.
    final class HandoffBundleView {
        var code: String
        var title: String
        var maximum: String
        var priority: String
        var currency: String
        var limit: String
        var margin: String
        var amount: String
        var specialtyText: String
        var reviewerText: String
        var sequence: String
        var statusLabel: String

        init(code: String, title: String, maximum: String, priority: String, currency: String, limit: String, margin: String, amount: String, specialtyText: String, reviewerText: String, sequence: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.priority = priority
            self.currency = currency
            self.limit = limit
            self.margin = margin
            self.amount = amount
            self.specialtyText = specialtyText
            self.reviewerText = reviewerText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffBundleView(_ item: HandoffBundle) -> HandoffBundleView {
        return HandoffBundleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            maximum: String(format: "%.2f", item.maximum),
            priority: String(item.priority),
            currency: item.currency,
            limit: String(item.limit),
            margin: String(format: "%.2f", item.margin),
            amount: String(format: "%.2f", item.amount),
            specialtyText: item.specialty,
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 64),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffBundleViews(_ items: [HandoffBundle]) -> [HandoffBundleView] {
        var views: [HandoffBundleView] = []
        for item in items {
            views.append(toHandoffBundleView(item))
        }
        return views
    }

    static func sumHandoffBundleView(_ view: HandoffBundleView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedMaximum + Double(parsedPriority) + Double(parsedLimit)
    }
}
