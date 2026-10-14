import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureAgreementsForNotice(_ items: [DisclosureAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveBatchedWitnessNoticesFromAgreement(_ items: [DisclosureAgreement]) -> [BatchedWitnessNotice] {
        var out: [BatchedWitnessNotice] = []
        for item in items {
            let derived = newBatchedWitnessNotice(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveBatchedWitnessNotice(_ item: BatchedWitnessNotice) -> String {
        return classifyDisclosurePolicy(item.netVolume())
    }
}
