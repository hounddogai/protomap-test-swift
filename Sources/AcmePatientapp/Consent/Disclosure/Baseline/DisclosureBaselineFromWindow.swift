import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormWindowsForBaseline(_ items: [ConsentFormWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveDisclosureBaselinesFromWindow(_ items: [ConsentFormWindow]) -> [DisclosureBaseline] {
        var out: [DisclosureBaseline] = []
        for item in items {
            let derived = newDisclosureBaseline(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateDisclosureBaseline(_ item: DisclosureBaseline) -> String {
        return consentFormWindowBucket(item.netLoad())
    }
}
