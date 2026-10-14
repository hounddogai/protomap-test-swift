import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardForecastsForCheckpoint(_ items: [BedBoardForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveBedBoardCheckpointsFromForecast(_ items: [BedBoardForecast]) -> [BedBoardCheckpoint] {
        var out: [BedBoardCheckpoint] = []
        for item in items {
            let derived = newBedBoardCheckpoint(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planBedBoardCheckpoint(_ item: BedBoardCheckpoint) -> String {
        return bedBoardForecastBucket(item.measuredValue())
    }
}
