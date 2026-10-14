import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictProxyVariancesForWindow(_ items: [StrictProxyVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveRollingProxyWindowsFromVariance(_ items: [StrictProxyVariance]) -> [RollingProxyWindow] {
        var out: [RollingProxyWindow] = []
        for item in items {
            let derived = newRollingProxyWindow(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeRollingProxyWindow(_ item: RollingProxyWindow) -> String {
        return normalizeStrictProxyVarianceCode(item.code)
    }
}
