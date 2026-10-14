import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimaryInventoryAgreementsForMetric(_ items: [PrimaryInventoryAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRollingFormularyMetricsFromAgreement(_ items: [PrimaryInventoryAgreement]) -> [RollingFormularyMetric] {
        var out: [RollingFormularyMetric] = []
        for item in items {
            let derived = newRollingFormularyMetric(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRollingFormularyMetric(_ item: RollingFormularyMetric) -> String {
        return primaryInventoryAgreementBucket(item.projectedExposure())
    }
}
