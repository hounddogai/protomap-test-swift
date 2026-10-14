import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result milestone.
    final class ResultMilestoneView {
        var code: String
        var name: String
        var batchSize: String
        var versionText: String
        var payer: String
        var externalRef: String
        var currencyText: String
        var diagnosisCode: String
        var categoryText: String
        var thresholdText: String
        var sourceText: String
        var statusLabel: String

        init(code: String, name: String, batchSize: String, versionText: String, payer: String, externalRef: String, currencyText: String, diagnosisCode: String, categoryText: String, thresholdText: String, sourceText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.versionText = versionText
            self.payer = payer
            self.externalRef = externalRef
            self.currencyText = currencyText
            self.diagnosisCode = diagnosisCode
            self.categoryText = categoryText
            self.thresholdText = thresholdText
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toResultMilestoneView(_ item: ResultMilestone) -> ResultMilestoneView {
        return ResultMilestoneView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            batchSize: String(item.batchSize),
            versionText: String(item.version),
            payer: item.payer,
            externalRef: item.externalRef,
            currencyText: item.currency,
            diagnosisCode: item.diagnosisCode,
            categoryText: item.category,
            thresholdText: String(format: "%.2f", item.threshold),
            sourceText: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultMilestoneViews(_ items: [ResultMilestone]) -> [ResultMilestoneView] {
        var views: [ResultMilestoneView] = []
        for item in items {
            views.append(toResultMilestoneView(item))
        }
        return views
    }

    static func sumResultMilestoneView(_ view: ResultMilestoneView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedVersion) + parsedThreshold
    }
}
