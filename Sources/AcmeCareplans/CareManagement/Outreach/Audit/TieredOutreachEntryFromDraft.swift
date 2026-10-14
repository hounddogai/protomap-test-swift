import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLegacyOutreachDraftsForEntry(_ items: [LegacyOutreachDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveTieredOutreachEntriesFromDraft(_ items: [LegacyOutreachDraft]) -> [TieredOutreachEntry] {
        var out: [TieredOutreachEntry] = []
        for item in items {
            let derived = newTieredOutreachEntry(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeTieredOutreachEntry(_ item: TieredOutreachEntry) -> String {
        return legacyOutreachDraftBucket(item.netValue())
    }
}
