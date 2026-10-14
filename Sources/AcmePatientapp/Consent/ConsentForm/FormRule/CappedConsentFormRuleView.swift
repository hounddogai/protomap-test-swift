import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped consent form rule.
    final class CappedConsentFormRuleView {
        var codeText: String
        var nameText: String
        var sequence: String
        var payerText: String
        var thresholdText: String
        var ceiling: String
        var channelText: String
        var statusLabel: String

        init(codeText: String, nameText: String, sequence: String, payerText: String, thresholdText: String, ceiling: String, channelText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.sequence = sequence
            self.payerText = payerText
            self.thresholdText = thresholdText
            self.ceiling = ceiling
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedConsentFormRuleView(_ item: CappedConsentFormRule) -> CappedConsentFormRuleView {
        return CappedConsentFormRuleView(
            codeText: item.code,
            nameText: item.name,
            sequence: String(item.sequence),
            payerText: item.payer,
            thresholdText: String(format: "%.2f", item.threshold),
            ceiling: String(format: "%.2f", item.ceiling),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedConsentFormRuleViews(_ items: [CappedConsentFormRule]) -> [CappedConsentFormRuleView] {
        var views: [CappedConsentFormRuleView] = []
        for item in items {
            views.append(toCappedConsentFormRuleView(item))
        }
        return views
    }

    static func sumCappedConsentFormRuleView(_ view: CappedConsentFormRuleView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedSequence) + parsedThreshold + parsedCeiling
    }
}
