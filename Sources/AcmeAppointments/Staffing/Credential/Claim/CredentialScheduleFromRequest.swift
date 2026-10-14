import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolRequestsForSchedule(_ items: [FloatPoolRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveCredentialSchedulesFromRequest(_ items: [FloatPoolRequest]) -> [CredentialSchedule] {
        var out: [CredentialSchedule] = []
        for item in items {
            let derived = newCredentialSchedule(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreCredentialSchedule(_ item: CredentialSchedule) -> String {
        return floatPoolTargetBucket(item.effectiveVolume())
    }
}
