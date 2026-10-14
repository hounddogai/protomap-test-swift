import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeBatchedCredentialSchedulesForTemplate(_ items: [BatchedCredentialSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveCredentialTemplatesFromSchedule(_ items: [BatchedCredentialSchedule]) -> [CredentialTemplate] {
        var out: [CredentialTemplate] = []
        for item in items {
            let derived = newCredentialTemplate(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectCredentialTemplate(_ item: CredentialTemplate) -> Double {
        return primaryCredentialEstimateWeight(1, active: true)
    }
}
