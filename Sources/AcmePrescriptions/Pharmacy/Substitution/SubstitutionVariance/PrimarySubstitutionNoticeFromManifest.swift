import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimarySubstitutionManifestsForNotice(_ items: [PrimarySubstitutionManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func derivePrimarySubstitutionNoticesFromManifest(_ items: [PrimarySubstitutionManifest]) -> [PrimarySubstitutionNotice] {
        var out: [PrimarySubstitutionNotice] = []
        for item in items {
            let derived = newPrimarySubstitutionNotice(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyPrimarySubstitutionNoticeExtra(_ item: PrimarySubstitutionNotice) -> Double {
        return substitutionEntryWeight(7, active: true)
    }
}
