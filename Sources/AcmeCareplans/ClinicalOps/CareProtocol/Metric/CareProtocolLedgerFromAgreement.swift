import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolAgreementsForLedger(_ items: [CareProtocolAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveCareProtocolLedgersFromAgreement(_ items: [CareProtocolAgreement]) -> [CareProtocolLedger] {
        var out: [CareProtocolLedger] = []
        for item in items {
            let derived = newCareProtocolLedger(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyCareProtocolLedger(_ item: CareProtocolLedger) -> String {
        return classifyCareProtocolScore(item.projectedValue())
    }
}
