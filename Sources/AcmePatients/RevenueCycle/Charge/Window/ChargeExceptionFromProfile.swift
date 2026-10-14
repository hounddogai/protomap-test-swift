import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeProfilesForException(_ items: [ChargeProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveChargeExceptionsFromProfile(_ items: [ChargeProfile]) -> [ChargeException] {
        var out: [ChargeException] = []
        for item in items {
            let derived = newChargeException(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeChargeException(_ item: ChargeException) -> String {
        return chargeNoticeBucket(item.projectedTotal())
    }
}
