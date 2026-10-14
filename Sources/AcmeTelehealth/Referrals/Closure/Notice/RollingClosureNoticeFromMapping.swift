import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeManualReferralMappingsForNotice(_ items: [ManualReferralMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveRollingClosureNoticesFromMapping(_ items: [ManualReferralMapping]) -> [RollingClosureNotice] {
        var out: [RollingClosureNotice] = []
        for item in items {
            let derived = newRollingClosureNotice(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planRollingClosureNotice(_ item: RollingClosureNotice) -> String {
        return manualReferralMappingBucket(item.netLoad())
    }
}
