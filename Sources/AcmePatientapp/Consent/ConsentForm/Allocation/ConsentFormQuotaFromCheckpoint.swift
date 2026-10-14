import AcmePlatform
import Foundation

extension Consent {
    static func summarizePrimaryProxyCheckpointsForQuota(_ items: [PrimaryProxyCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveConsentFormQuotasFromCheckpoint(_ items: [PrimaryProxyCheckpoint]) -> [ConsentFormQuota] {
        var out: [ConsentFormQuota] = []
        for item in items {
            let derived = newConsentFormQuota(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceConsentFormQuota(_ item: ConsentFormQuota) -> Double {
        return lenientProxyReviewWeight(1, active: true)
    }
}
