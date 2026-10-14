import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingConsentFormSchedulesForWindow(_ items: [RollingConsentFormSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackLanguageWindowsFromSchedule(_ items: [RollingConsentFormSchedule]) -> [FallbackLanguageWindow] {
        var out: [FallbackLanguageWindow] = []
        for item in items {
            let derived = newFallbackLanguageWindow(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateFallbackLanguageWindow(_ item: FallbackLanguageWindow) -> String {
        return cappedConsentFormNoticeBucket(item.effectiveLoad())
    }
}
