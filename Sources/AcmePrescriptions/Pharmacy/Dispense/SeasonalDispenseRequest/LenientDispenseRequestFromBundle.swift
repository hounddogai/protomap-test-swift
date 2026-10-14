import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLenientDispenseBundlesForRequest(_ items: [LenientDispenseBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveLenientDispenseRequestsFromBundle(_ items: [LenientDispenseBundle]) -> [LenientDispenseRequest] {
        var out: [LenientDispenseRequest] = []
        for item in items {
            let derived = newLenientDispenseRequest(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileLenientDispenseRequest(_ item: LenientDispenseRequest) -> String {
        return lenientDispenseBundleBucket(item.effectiveVolume())
    }
}
