import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierRecordsForException(_ items: [CourierRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalSpecimenExceptionsFromRecord(_ items: [CourierRecord]) -> [GlobalSpecimenException] {
        var out: [GlobalSpecimenException] = []
        for item in items {
            let derived = newGlobalSpecimenException(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveGlobalSpecimenException(_ item: GlobalSpecimenException) -> String {
        return cappedCourierMetricBucket(item.netExposure())
    }
}
