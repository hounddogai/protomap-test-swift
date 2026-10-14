import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultManifestsForException(_ items: [ResultManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveCappedCourierExceptionsFromManifest(_ items: [ResultManifest]) -> [CappedCourierException] {
        var out: [CappedCourierException] = []
        for item in items {
            let derived = newCappedCourierException(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankCappedCourierException(_ item: CappedCourierException) -> String {
        return classifyLegacyResultAgreement(item.adjustedExposure())
    }
}
