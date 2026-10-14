import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierManifestsForWindow(_ items: [CourierManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveAccessionWindowsFromManifest(_ items: [CourierManifest]) -> [AccessionWindow] {
        var out: [AccessionWindow] = []
        for item in items {
            let derived = newAccessionWindow(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAccessionWindow(_ item: AccessionWindow) -> String {
        return defaultCourierClaimBucket(item.projectedVolume())
    }
}
