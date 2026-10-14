import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftAuditsForRequest(_ items: [ShiftAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveGlobalCredentialRequestsFromAudit(_ items: [ShiftAudit]) -> [GlobalCredentialRequest] {
        var out: [GlobalCredentialRequest] = []
        for item in items {
            let derived = newGlobalCredentialRequest(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceGlobalCredentialRequest(_ item: GlobalCredentialRequest) -> String {
        return classifyShiftAudit(item.projectedVolume())
    }
}
