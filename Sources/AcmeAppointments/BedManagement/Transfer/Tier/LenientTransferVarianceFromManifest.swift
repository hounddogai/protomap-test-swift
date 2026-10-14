import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardManifestsForVariance(_ items: [BedBoardManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientTransferVariancesFromManifest(_ items: [BedBoardManifest]) -> [LenientTransferVariance] {
        var out: [LenientTransferVariance] = []
        for item in items {
            let derived = newLenientTransferVariance(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchLenientTransferVariance(_ item: LenientTransferVariance) -> String {
        return normalizeAdaptiveBedBoardReviewCode(item.code)
    }
}
