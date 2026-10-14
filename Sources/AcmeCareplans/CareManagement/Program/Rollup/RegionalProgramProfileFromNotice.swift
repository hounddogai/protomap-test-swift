import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGlobalCareGapNoticesForProfile(_ items: [GlobalCareGapNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveRegionalProgramProfilesFromNotice(_ items: [GlobalCareGapNotice]) -> [RegionalProgramProfile] {
        var out: [RegionalProgramProfile] = []
        for item in items {
            let derived = newRegionalProgramProfile(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyRegionalProgramProfile(_ item: RegionalProgramProfile) -> Double {
        return careGapCycleWeight(5, active: true)
    }
}
