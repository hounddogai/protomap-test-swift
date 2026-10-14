import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimarySkillMixPreferencesForTarget(_ items: [PrimarySkillMixPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveGlobalFloatPoolTargetsFromPreference(_ items: [PrimarySkillMixPreference]) -> [GlobalFloatPoolTarget] {
        var out: [GlobalFloatPoolTarget] = []
        for item in items {
            let derived = newGlobalFloatPoolTarget(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceGlobalFloatPoolTarget(_ item: GlobalFloatPoolTarget) -> String {
        return regionalSkillMixLedgerBucket(item.adjustedValue())
    }
}
