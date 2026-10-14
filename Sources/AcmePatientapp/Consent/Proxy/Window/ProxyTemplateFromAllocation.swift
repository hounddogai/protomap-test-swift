import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessAllocationsForTemplate(_ items: [WitnessAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveProxyTemplatesFromAllocation(_ items: [WitnessAllocation]) -> [ProxyTemplate] {
        var out: [ProxyTemplate] = []
        for item in items {
            let derived = newProxyTemplate(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeProxyTemplate(_ item: ProxyTemplate) -> String {
        return normalizeWitnessGroupCode(item.code)
    }
}
