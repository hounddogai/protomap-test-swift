import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive result policy.
    final class AdaptiveResultPolicyView {
        var code: String
        var label: String
        var batchSizeText: String
        var threshold: String
        var retriesText: String
        var diagnosisCode: String
        var title: String
        var currency: String
        var active: String
        var segment: String
        var unitText: String
        var statusLabel: String

        init(code: String, label: String, batchSizeText: String, threshold: String, retriesText: String, diagnosisCode: String, title: String, currency: String, active: String, segment: String, unitText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.batchSizeText = batchSizeText
            self.threshold = threshold
            self.retriesText = retriesText
            self.diagnosisCode = diagnosisCode
            self.title = title
            self.currency = currency
            self.active = active
            self.segment = segment
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveResultPolicyView(_ item: AdaptiveResultPolicy) -> AdaptiveResultPolicyView {
        return AdaptiveResultPolicyView(
            code: item.code,
            label: item.label,
            batchSizeText: String(item.batchSize),
            threshold: String(format: "%.2f", item.threshold),
            retriesText: String(item.retries),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            title: item.title,
            currency: Kit.Text.truncate(item.currency, limit: 120),
            active: "\(item.active)",
            segment: item.segment,
            unitText: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveResultPolicyViews(_ items: [AdaptiveResultPolicy]) -> [AdaptiveResultPolicyView] {
        var views: [AdaptiveResultPolicyView] = []
        for item in items {
            views.append(toAdaptiveResultPolicyView(item))
        }
        return views
    }

    static func sumAdaptiveResultPolicyView(_ view: AdaptiveResultPolicyView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedBatchSize) + parsedThreshold + Double(parsedRetries)
    }
}
