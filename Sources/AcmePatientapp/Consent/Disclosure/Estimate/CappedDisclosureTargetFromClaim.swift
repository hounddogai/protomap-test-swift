import AcmePlatform
import Foundation

extension Consent {
    static func summarizeManualLanguageClaimsForTarget(_ items: [ManualLanguageClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveCappedDisclosureTargetsFromClaim(_ items: [ManualLanguageClaim]) -> [CappedDisclosureTarget] {
        var out: [CappedDisclosureTarget] = []
        for item in items {
            let derived = newCappedDisclosureTarget(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchCappedDisclosureTarget(_ item: CappedDisclosureTarget) -> String {
        return manualLanguageClaimBucket(item.netLoad())
    }
}
