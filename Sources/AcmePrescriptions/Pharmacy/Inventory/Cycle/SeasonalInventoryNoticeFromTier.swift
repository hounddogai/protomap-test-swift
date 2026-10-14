import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimarySubstitutionTiersForNotice(_ items: [PrimarySubstitutionTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveSeasonalInventoryNoticesFromTier(_ items: [PrimarySubstitutionTier]) -> [SeasonalInventoryNotice] {
        var out: [SeasonalInventoryNotice] = []
        for item in items {
            let derived = newSeasonalInventoryNotice(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeSeasonalInventoryNotice(_ item: SeasonalInventoryNotice) -> String {
        return substitutionProposalBucket(item.weightedVolume())
    }
}
