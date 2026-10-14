import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialSegmentsForSnapshot(_ items: [DenialSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveRollingAuthorizationSnapshotsFromSegment(_ items: [DenialSegment]) -> [RollingAuthorizationSnapshot] {
        var out: [RollingAuthorizationSnapshot] = []
        for item in items {
            let derived = newRollingAuthorizationSnapshot(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceRollingAuthorizationSnapshot(_ item: RollingAuthorizationSnapshot) -> String {
        return normalizeDenialSegmentCode(item.code)
    }
}
