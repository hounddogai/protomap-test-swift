import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDefaultSubstitutionTiersForNotice(_ items: [DefaultSubstitutionTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveDispenseNoticesFromTier(_ items: [DefaultSubstitutionTier]) -> [DispenseNotice] {
        var out: [DispenseNotice] = []
        for item in items {
            let derived = newDispenseNotice(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveDispenseNotice(_ item: DispenseNotice) -> String {
        return normalizeManualSubstitutionDigestCode(item.code)
    }
}
