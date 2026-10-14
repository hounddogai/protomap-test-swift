import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffMappingsForLedger(_ items: [HandoffMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveFallbackCareProtocolLedgersFromMapping(_ items: [HandoffMapping]) -> [FallbackCareProtocolLedger] {
        var out: [FallbackCareProtocolLedger] = []
        for item in items {
            let derived = newFallbackCareProtocolLedger(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeFallbackCareProtocolLedger(_ item: FallbackCareProtocolLedger) -> String {
        return normalizeHandoffManifestCode(item.code)
    }
}
