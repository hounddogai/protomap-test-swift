import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanQuotasForRequest(_ items: [DischargePlanQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveCleaningRequestsFromQuota(_ items: [DischargePlanQuota]) -> [CleaningRequest] {
        var out: [CleaningRequest] = []
        for item in items {
            let derived = newCleaningRequest(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreCleaningRequest(_ item: CleaningRequest) -> String {
        return dischargePlanEstimateBucket(item.netExposure())
    }

    static func summarizeCleaningQuotasForRequest(_ items: [CleaningQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveCleaningRequestsFromQuotaExtra(_ items: [CleaningQuota]) -> [CleaningRequest] {
        var out: [CleaningRequest] = []
        for item in items {
            let derived = newCleaningRequest(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeCleaningRequest(_ item: CleaningRequest) -> String {
        return normalizeCleaningPlanCode(item.code)
    }
}
