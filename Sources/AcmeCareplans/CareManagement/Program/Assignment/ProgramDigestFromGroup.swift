import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLenientProgramGroupsForDigest(_ items: [LenientProgramGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveProgramDigestsFromGroup(_ items: [LenientProgramGroup]) -> [ProgramDigest] {
        var out: [ProgramDigest] = []
        for item in items {
            let derived = newProgramDigest(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeProgramDigest(_ item: ProgramDigest) -> String {
        return legacyProgramNoticeBucket(item.projectedVolume())
    }
}
