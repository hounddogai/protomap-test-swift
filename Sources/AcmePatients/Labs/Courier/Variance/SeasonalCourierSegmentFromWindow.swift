import AcmePlatform
import Foundation

extension Labs {
    static func summarizeDefaultAccessionWindowsForSegment(_ items: [DefaultAccessionWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalCourierSegmentsFromWindow(_ items: [DefaultAccessionWindow]) -> [SeasonalCourierSegment] {
        var out: [SeasonalCourierSegment] = []
        for item in items {
            let derived = newSeasonalCourierSegment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeSeasonalCourierSegment(_ item: SeasonalCourierSegment) -> String {
        return normalizeStrictAccessionBundleCode(item.code)
    }
}
