import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLenientProxySchedulesForCheckpoint(_ items: [LenientProxySchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func derivePendingConsentFormCheckpointsFromSchedule(_ items: [LenientProxySchedule]) -> [PendingConsentFormCheckpoint] {
        var out: [PendingConsentFormCheckpoint] = []
        for item in items {
            let derived = newPendingConsentFormCheckpoint(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balancePendingConsentFormCheckpoint(_ item: PendingConsentFormCheckpoint) -> String {
        return classifyLenientProxyClaim(item.netExposure())
    }
}
