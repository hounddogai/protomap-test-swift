import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLenientDenialManifestsForRecord(_ items: [LenientDenialManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveDenialRecordsFromManifest(_ items: [LenientDenialManifest]) -> [DenialRecord] {
        var out: [DenialRecord] = []
        for item in items {
            let derived = newDenialRecord(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitDenialRecord(_ item: DenialRecord) -> String {
        return strictDenialTargetBucket(item.netValue())
    }
}
