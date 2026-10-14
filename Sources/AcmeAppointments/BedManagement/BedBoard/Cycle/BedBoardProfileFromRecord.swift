import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusRecordsForProfile(_ items: [CensusRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveBedBoardProfilesFromRecord(_ items: [CensusRecord]) -> [BedBoardProfile] {
        var out: [BedBoardProfile] = []
        for item in items {
            let derived = newBedBoardProfile(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceBedBoardProfile(_ item: BedBoardProfile) -> String {
        return normalizeLegacyCensusDraftCode(item.code)
    }
}
