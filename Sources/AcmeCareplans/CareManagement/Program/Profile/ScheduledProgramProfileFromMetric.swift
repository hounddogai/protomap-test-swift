import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachMetricsForProfile(_ items: [OutreachMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveScheduledProgramProfilesFromMetric(_ items: [OutreachMetric]) -> [ScheduledProgramProfile] {
        var out: [ScheduledProgramProfile] = []
        for item in items {
            let derived = newScheduledProgramProfile(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignScheduledProgramProfile(_ item: ScheduledProgramProfile) -> String {
        return normalizeOutreachMetricCode(item.code)
    }
}
