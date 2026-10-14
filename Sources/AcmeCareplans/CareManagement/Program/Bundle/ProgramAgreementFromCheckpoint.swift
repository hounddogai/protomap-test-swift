import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingOutreachCheckpointsForAgreement(_ items: [PendingOutreachCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveProgramAgreementsFromCheckpoint(_ items: [PendingOutreachCheckpoint]) -> [ProgramAgreement] {
        var out: [ProgramAgreement] = []
        for item in items {
            let derived = newProgramAgreement(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateProgramAgreement(_ item: ProgramAgreement) -> Double {
        return cappedOutreachTemplateWeight(2, active: true)
    }
}
