import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLenientOvertimeProposalsForRequest(_ items: [LenientOvertimeProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveDefaultCredentialRequestsFromProposal(_ items: [LenientOvertimeProposal]) -> [DefaultCredentialRequest] {
        var out: [DefaultCredentialRequest] = []
        for item in items {
            let derived = newDefaultCredentialRequest(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleDefaultCredentialRequest(_ item: DefaultCredentialRequest) -> String {
        return classifyFallbackOvertimeCheckpoint(item.projectedTotal())
    }
}
