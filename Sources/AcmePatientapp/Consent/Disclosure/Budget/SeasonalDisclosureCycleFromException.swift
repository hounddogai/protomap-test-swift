import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingRevocationExceptionsForCycle(_ items: [RollingRevocationException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveSeasonalDisclosureCyclesFromException(_ items: [RollingRevocationException]) -> [SeasonalDisclosureCycle] {
        var out: [SeasonalDisclosureCycle] = []
        for item in items {
            let derived = newSeasonalDisclosureCycle(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifySeasonalDisclosureCycleExtra(_ item: SeasonalDisclosureCycle) -> String {
        return classifyLenientRevocationManifest(item.netValue())
    }
}
