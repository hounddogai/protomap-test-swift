import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingConsentFormSegmentsForRecord(_ items: [RollingConsentFormSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryDisclosureRecordsFromSegment(_ items: [RollingConsentFormSegment]) -> [PrimaryDisclosureRecord] {
        var out: [PrimaryDisclosureRecord] = []
        for item in items {
            let derived = newPrimaryDisclosureRecord(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyPrimaryDisclosureRecord(_ item: PrimaryDisclosureRecord) -> String {
        return manualConsentFormWindowBucket(item.projectedVolume())
    }
}
