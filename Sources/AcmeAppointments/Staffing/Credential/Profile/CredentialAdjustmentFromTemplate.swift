import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeWeightedSkillMixTemplatesForAdjustment(_ items: [WeightedSkillMixTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCredentialAdjustmentsFromTemplate(_ items: [WeightedSkillMixTemplate]) -> [CredentialAdjustment] {
        var out: [CredentialAdjustment] = []
        for item in items {
            let derived = newCredentialAdjustment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitCredentialAdjustment(_ item: CredentialAdjustment) -> Double {
        return fallbackSkillMixLedgerWeight(8, active: true)
    }
}
