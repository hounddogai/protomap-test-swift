import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceScoresForMapping(_ items: [RemittanceScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func derivePendingRemittanceMappingsFromScore(_ items: [RemittanceScore]) -> [PendingRemittanceMapping] {
        var out: [PendingRemittanceMapping] = []
        for item in items {
            let derived = newPendingRemittanceMapping(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizePendingRemittanceMapping(_ item: PendingRemittanceMapping) -> String {
        return classifyFallbackRemittanceTarget(item.projectedExposure())
    }
}
