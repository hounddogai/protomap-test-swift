import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolLedgersForTemplate(_ items: [FloatPoolLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveFallbackShiftTemplatesFromLedger(_ items: [FloatPoolLedger]) -> [FallbackShiftTemplate] {
        var out: [FallbackShiftTemplate] = []
        for item in items {
            let derived = newFallbackShiftTemplate(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveFallbackShiftTemplate(_ item: FallbackShiftTemplate) -> Double {
        return floatPoolLedgerWeight(3, active: true)
    }
}
