import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationMappingsForSummaryAudit(_ items: [RevocationMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveDefaultDisclosureSummariesFromMapping(_ items: [RevocationMapping]) -> [DefaultDisclosureSummary] {
        var out: [DefaultDisclosureSummary] = []
        for item in items {
            let derived = newDefaultDisclosureSummary(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveDefaultDisclosureSummary(_ item: DefaultDisclosureSummary) -> String {
        return normalizeRegionalRevocationAgreementCode(item.code)
    }
}
