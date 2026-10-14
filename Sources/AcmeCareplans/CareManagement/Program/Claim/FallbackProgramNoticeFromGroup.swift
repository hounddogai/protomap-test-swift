import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapGroupsForNotice(_ items: [CareGapGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveFallbackProgramNoticesFromGroup(_ items: [CareGapGroup]) -> [FallbackProgramNotice] {
        var out: [FallbackProgramNotice] = []
        for item in items {
            let derived = newFallbackProgramNotice(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreFallbackProgramNotice(_ item: FallbackProgramNotice) -> String {
        return classifyCareGapQuota(item.netVolume())
    }
}
