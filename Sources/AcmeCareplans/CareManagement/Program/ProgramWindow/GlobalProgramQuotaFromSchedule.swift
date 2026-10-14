import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeTieredCareGapSchedulesForQuota(_ items: [TieredCareGapSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveGlobalProgramQuotasFromSchedule(_ items: [TieredCareGapSchedule]) -> [GlobalProgramQuota] {
        var out: [GlobalProgramQuota] = []
        for item in items {
            let derived = newGlobalProgramQuota(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchGlobalProgramQuota(_ item: GlobalProgramQuota) -> String {
        return tieredCareGapScheduleBucket(item.projectedVolume())
    }
}
