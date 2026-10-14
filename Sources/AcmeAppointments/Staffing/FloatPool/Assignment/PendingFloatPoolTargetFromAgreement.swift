import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftAgreementsForTarget(_ items: [ShiftAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingFloatPoolTargetsFromAgreement(_ items: [ShiftAgreement]) -> [PendingFloatPoolTarget] {
        var out: [PendingFloatPoolTarget] = []
        for item in items {
            let derived = newPendingFloatPoolTarget(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergePendingFloatPoolTarget(_ item: PendingFloatPoolTarget) -> String {
        return normalizeShiftAgreementCode(item.code)
    }
}
