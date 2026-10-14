import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLenientShiftQuotasForAgreement(_ items: [LenientShiftQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveShiftAgreementsFromQuota(_ items: [LenientShiftQuota]) -> [ShiftAgreement] {
        var out: [ShiftAgreement] = []
        for item in items {
            let derived = newShiftAgreement(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreShiftAgreement(_ item: ShiftAgreement) -> String {
        return normalizeSeasonalShiftMetricCode(item.code)
    }
}
