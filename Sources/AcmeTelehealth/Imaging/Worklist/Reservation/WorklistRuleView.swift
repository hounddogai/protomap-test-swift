import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist rule.
    final class WorklistRuleView {
        var code: String
        var name: String
        var batchSizeText: String
        var ratio: String
        var attempts: String
        var statusLabel: String

        init(code: String, name: String, batchSizeText: String, ratio: String, attempts: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.batchSizeText = batchSizeText
            self.ratio = ratio
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistRuleView(_ item: WorklistRule) -> WorklistRuleView {
        return WorklistRuleView(
            code: item.code,
            name: item.name,
            batchSizeText: String(item.batchSize),
            ratio: String(format: "%.2f", item.ratio),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistRuleViews(_ items: [WorklistRule]) -> [WorklistRuleView] {
        var views: [WorklistRuleView] = []
        for item in items {
            views.append(toWorklistRuleView(item))
        }
        return views
    }

    static func sumWorklistRuleView(_ view: WorklistRuleView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedBatchSize) + parsedRatio + Double(parsedAttempts)
    }
}
