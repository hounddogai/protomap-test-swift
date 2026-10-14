import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLenientInventoryManifestsForRequest(_ items: [LenientInventoryManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveRegionalDispenseRequestsFromManifest(_ items: [LenientInventoryManifest]) -> [RegionalDispenseRequest] {
        var out: [RegionalDispenseRequest] = []
        for item in items {
            let derived = newRegionalDispenseRequest(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyRegionalDispenseRequest(_ item: RegionalDispenseRequest) -> String {
        return normalizeLenientInventoryManifestCode(item.code)
    }
}
