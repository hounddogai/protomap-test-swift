import AcmePlatform
import Foundation

extension Consent {
    static func summarizeProxyWindowsForCheckpoint(_ items: [ProxyWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveProxyCheckpointsFromWindow(_ items: [ProxyWindow]) -> [ProxyCheckpoint] {
        var out: [ProxyCheckpoint] = []
        for item in items {
            let derived = newProxyCheckpoint(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyProxyCheckpoint(_ item: ProxyCheckpoint) -> String {
        return normalizeProxyNoticeCode(item.code)
    }
}
