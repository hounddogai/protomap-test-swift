import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialSchedulesForSegment(_ items: [CredentialSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveCredentialSegmentsFromSchedule(_ items: [CredentialSchedule]) -> [CredentialSegment] {
        var out: [CredentialSegment] = []
        for item in items {
            let derived = newCredentialSegment(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchCredentialSegment(_ item: CredentialSegment) -> String {
        return normalizeCredentialScheduleCode(item.code)
    }
}
