import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientCensusRecordsForDigest(_ items: [LenientCensusRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveStrictIsolationDigestsFromRecord(_ items: [LenientCensusRecord]) -> [StrictIsolationDigest] {
        var out: [StrictIsolationDigest] = []
        for item in items {
            let derived = newStrictIsolationDigest(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreStrictIsolationDigest(_ item: StrictIsolationDigest) -> String {
        return manualCensusForecastBucket(item.effectiveExposure())
    }
}
