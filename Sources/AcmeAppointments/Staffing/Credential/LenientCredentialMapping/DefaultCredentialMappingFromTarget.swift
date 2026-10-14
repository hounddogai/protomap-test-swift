import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeManualFloatPoolTargetsForMapping(_ items: [ManualFloatPoolTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveDefaultCredentialMappingsFromTarget(_ items: [ManualFloatPoolTarget]) -> [DefaultCredentialMapping] {
        var out: [DefaultCredentialMapping] = []
        for item in items {
            let derived = newDefaultCredentialMapping(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateDefaultCredentialMapping(_ item: DefaultCredentialMapping) -> String {
        return classifyFallbackFloatPoolAdjustment(item.projectedTotal())
    }
}
