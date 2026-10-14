import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingConsentFormTargetsForException(_ items: [RollingConsentFormTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledLanguageExceptionsFromTarget(_ items: [RollingConsentFormTarget]) -> [ScheduledLanguageException] {
        var out: [ScheduledLanguageException] = []
        for item in items {
            let derived = newScheduledLanguageException(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankScheduledLanguageException(_ item: ScheduledLanguageException) -> String {
        return classifyAdaptiveConsentFormBundle(item.adjustedValue())
    }
}
