import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFallbackShiftMappingsForBaseline(_ items: [FallbackShiftMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveCredentialBaselinesFromMapping(_ items: [FallbackShiftMapping]) -> [CredentialBaseline] {
        var out: [CredentialBaseline] = []
        for item in items {
            let derived = newCredentialBaseline(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeCredentialBaseline(_ item: CredentialBaseline) -> String {
        return normalizeLegacyShiftRollupCode(item.code)
    }
}
