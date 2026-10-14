import AcmePlatform
import Foundation

extension Labs {
    static func summarizeDefaultSpecimenPlansForQuota(_ items: [DefaultSpecimenPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveResultQuotasFromPlan(_ items: [DefaultSpecimenPlan]) -> [ResultQuota] {
        var out: [ResultQuota] = []
        for item in items {
            let derived = newResultQuota(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveResultQuota(_ item: ResultQuota) -> String {
        return batchedSpecimenPolicyBucket(item.projectedTotal())
    }
}
