import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolAgreementsForPolicy(_ items: [CareProtocolAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveReadPoliciesFromAgreement(_ items: [CareProtocolAgreement]) -> [ReadPolicy] {
        var out: [ReadPolicy] = []
        for item in items {
            let derived = newReadPolicy(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignReadPolicy(_ item: ReadPolicy) -> String {
        return careProtocolReservationBucket(item.weightedValue())
    }
}
