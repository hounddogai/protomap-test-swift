import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeManualOutreachAssignmentsForSnapshot(_ items: [ManualOutreachAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveProgramSnapshotsFromAssignment(_ items: [ManualOutreachAssignment]) -> [ProgramSnapshot] {
        var out: [ProgramSnapshot] = []
        for item in items {
            let derived = newProgramSnapshot(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankProgramSnapshot(_ item: ProgramSnapshot) -> String {
        return classifyLenientOutreachSlot(item.adjustedLoad())
    }
}
