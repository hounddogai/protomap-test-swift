import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLenientHandoffAuditsForAudit(_ items: [LenientHandoffAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveRollingCareProtocolAuditsFromAudit(_ items: [LenientHandoffAudit]) -> [RollingCareProtocolAudit] {
        var out: [RollingCareProtocolAudit] = []
        for item in items {
            let derived = newRollingCareProtocolAudit(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileRollingCareProtocolAudit(_ item: RollingCareProtocolAudit) -> String {
        return lenientHandoffAuditBucket(item.measuredValue())
    }
}
