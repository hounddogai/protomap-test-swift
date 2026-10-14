import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramVariancesForAgreement(_ items: [ProgramVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveOutreachAgreementsFromVariance(_ items: [ProgramVariance]) -> [OutreachAgreement] {
        var out: [OutreachAgreement] = []
        for item in items {
            let derived = newOutreachAgreement(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankOutreachAgreement(_ item: OutreachAgreement) -> Double {
        return tieredProgramPreferenceWeight(6, active: true)
    }
}
