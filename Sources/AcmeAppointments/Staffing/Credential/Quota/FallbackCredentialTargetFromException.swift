import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLegacyShiftExceptionsForTarget(_ items: [LegacyShiftException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveFallbackCredentialTargetsFromException(_ items: [LegacyShiftException]) -> [FallbackCredentialTarget] {
        var out: [FallbackCredentialTarget] = []
        for item in items {
            let derived = newFallbackCredentialTarget(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignFallbackCredentialTarget(_ item: FallbackCredentialTarget) -> String {
        return normalizeLegacyShiftExceptionCode(item.code)
    }
}
