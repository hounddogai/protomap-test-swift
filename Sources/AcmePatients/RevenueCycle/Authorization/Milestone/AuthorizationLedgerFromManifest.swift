import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLenientDenialManifestsForLedger(_ items: [LenientDenialManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveAuthorizationLedgersFromManifest(_ items: [LenientDenialManifest]) -> [AuthorizationLedger] {
        var out: [AuthorizationLedger] = []
        for item in items {
            let derived = newAuthorizationLedger(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planAuthorizationLedger(_ item: AuthorizationLedger) -> Double {
        return lenientDenialManifestWeight(8, active: true)
    }
}
