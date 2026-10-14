import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseWindowsForTarget(_ items: [DispenseWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveGlobalSubstitutionTargetsFromWindow(_ items: [DispenseWindow]) -> [GlobalSubstitutionTarget] {
        var out: [GlobalSubstitutionTarget] = []
        for item in items {
            let derived = newGlobalSubstitutionTarget(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyGlobalSubstitutionTarget(_ item: GlobalSubstitutionTarget) -> Double {
        return scheduledDispenseAgreementWeight(6, active: true)
    }
}
