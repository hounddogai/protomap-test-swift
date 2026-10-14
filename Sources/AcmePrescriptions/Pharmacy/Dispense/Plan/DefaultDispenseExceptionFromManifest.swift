import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeStrictInteractionManifestsForException(_ items: [StrictInteractionManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveDefaultDispenseExceptionsFromManifest(_ items: [StrictInteractionManifest]) -> [DefaultDispenseException] {
        var out: [DefaultDispenseException] = []
        for item in items {
            let derived = newDefaultDispenseException(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreDefaultDispenseException(_ item: DefaultDispenseException) -> String {
        return classifyGlobalInteractionBaseline(item.adjustedVolume())
    }
}
