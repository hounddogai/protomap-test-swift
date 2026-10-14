import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftExceptionsForPolicy(_ items: [ShiftException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveFloatPoolPoliciesFromException(_ items: [ShiftException]) -> [FloatPoolPolicy] {
        var out: [FloatPoolPolicy] = []
        for item in items {
            let derived = newFloatPoolPolicy(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileFloatPoolPolicy(_ item: FloatPoolPolicy) -> String {
        return normalizeShiftPreferenceCode(item.code)
    }
}
