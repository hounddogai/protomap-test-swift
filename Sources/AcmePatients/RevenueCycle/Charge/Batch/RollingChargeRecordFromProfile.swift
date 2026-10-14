import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialProfilesForRecord(_ items: [DenialProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveRollingChargeRecordsFromProfile(_ items: [DenialProfile]) -> [RollingChargeRecord] {
        var out: [RollingChargeRecord] = []
        for item in items {
            let derived = newRollingChargeRecord(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveRollingChargeRecord(_ item: RollingChargeRecord) -> String {
        return denialVarianceBucket(item.effectiveLoad())
    }
}
