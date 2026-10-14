import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLegacyCensusTiersForProposal(_ items: [LegacyCensusTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveDefaultTransferProposalsFromTier(_ items: [LegacyCensusTier]) -> [DefaultTransferProposal] {
        var out: [DefaultTransferProposal] = []
        for item in items {
            let derived = newDefaultTransferProposal(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleDefaultTransferProposal(_ item: DefaultTransferProposal) -> Double {
        return fallbackCensusSnapshotWeight(4, active: true)
    }
}
