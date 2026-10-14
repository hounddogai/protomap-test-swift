import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeGlobalTaskWindowsForMapping(_ items: [GlobalTaskWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveManualCareProtocolMappingsFromWindow(_ items: [GlobalTaskWindow]) -> [ManualCareProtocolMapping] {
        var out: [ManualCareProtocolMapping] = []
        for item in items {
            let derived = newManualCareProtocolMapping(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveManualCareProtocolMapping(_ item: ManualCareProtocolMapping) -> String {
        return normalizeWeightedTaskManifestCode(item.code)
    }
}
