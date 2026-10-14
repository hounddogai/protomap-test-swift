import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLenientAccessionCheckpointsForProfile(_ items: [LenientAccessionCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveCappedCourierProfilesFromCheckpoint(_ items: [LenientAccessionCheckpoint]) -> [CappedCourierProfile] {
        var out: [CappedCourierProfile] = []
        for item in items {
            let derived = newCappedCourierProfile(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeCappedCourierProfile(_ item: CappedCourierProfile) -> String {
        return classifyLenientAccessionCheckpoint(item.projectedLoad())
    }
}
