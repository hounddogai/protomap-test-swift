import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelThresholdsForSegment(_ items: [PanelThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveResultSegmentsFromThreshold(_ items: [PanelThreshold]) -> [ResultSegment] {
        var out: [ResultSegment] = []
        for item in items {
            let derived = newResultSegment(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignResultSegment(_ item: ResultSegment) -> String {
        return classifyPanelSummary(item.measuredValue())
    }
}
