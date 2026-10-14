import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictRevocationBatchesForProfile(_ items: [StrictRevocationBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveGlobalDisclosureProfilesFromBatch(_ items: [StrictRevocationBatch]) -> [GlobalDisclosureProfile] {
        var out: [GlobalDisclosureProfile] = []
        for item in items {
            let derived = newGlobalDisclosureProfile(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleGlobalDisclosureProfile(_ item: GlobalDisclosureProfile) -> String {
        return classifyBatchedRevocationTarget(item.measuredValue())
    }
}
