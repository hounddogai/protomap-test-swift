import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryFloatPoolManifestsForProfile(_ items: [PrimaryFloatPoolManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveScheduledShiftProfilesFromManifest(_ items: [PrimaryFloatPoolManifest]) -> [ScheduledShiftProfile] {
        var out: [ScheduledShiftProfile] = []
        for item in items {
            let derived = newScheduledShiftProfile(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeScheduledShiftProfile(_ item: ScheduledShiftProfile) -> Double {
        return primaryFloatPoolManifestWeight(5, active: true)
    }
}
