import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimarySubstitutionTiersForSnapshot(_ items: [PrimarySubstitutionTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveRecallSnapshotsFromTier(_ items: [PrimarySubstitutionTier]) -> [RecallSnapshot] {
        var out: [RecallSnapshot] = []
        for item in items {
            let derived = newRecallSnapshot(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankRecallSnapshot(_ item: RecallSnapshot) -> String {
        return normalizeSubstitutionProposalCode(item.code)
    }
}
