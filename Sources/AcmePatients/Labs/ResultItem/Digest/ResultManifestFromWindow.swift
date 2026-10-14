import AcmePlatform
import Foundation

extension Labs {
    static func summarizePrimaryAccessionWindowsForManifest(_ items: [PrimaryAccessionWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveResultManifestsFromWindow(_ items: [PrimaryAccessionWindow]) -> [ResultManifest] {
        var out: [ResultManifest] = []
        for item in items {
            let derived = newResultManifest(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectResultManifest(_ item: ResultManifest) -> String {
        return classifyPrimaryAccessionWindow(item.projectedVolume())
    }
}
