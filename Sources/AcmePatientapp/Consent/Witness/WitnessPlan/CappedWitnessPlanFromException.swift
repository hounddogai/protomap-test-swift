import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingRevocationExceptionsForPlan(_ items: [RollingRevocationException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveCappedWitnessPlansFromException(_ items: [RollingRevocationException]) -> [CappedWitnessPlan] {
        var out: [CappedWitnessPlan] = []
        for item in items {
            let derived = newCappedWitnessPlan(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankCappedWitnessPlan(_ item: CappedWitnessPlan) -> String {
        return normalizeRollingRevocationExceptionCode(item.code)
    }
}
