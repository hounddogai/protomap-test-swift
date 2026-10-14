import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultProgramAssignmentsForTemplate(_ items: [DefaultProgramAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveProgramTemplatesFromAssignment(_ items: [DefaultProgramAssignment]) -> [ProgramTemplate] {
        var out: [ProgramTemplate] = []
        for item in items {
            let derived = newProgramTemplate(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveProgramTemplate(_ item: ProgramTemplate) -> String {
        return normalizeDefaultProgramAssignmentCode(item.code)
    }
}
