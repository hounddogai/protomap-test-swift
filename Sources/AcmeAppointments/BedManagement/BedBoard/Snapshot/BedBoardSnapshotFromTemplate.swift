import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeFallbackTransferTemplatesForSnapshot(_ items: [FallbackTransferTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveBedBoardSnapshotsFromTemplate(_ items: [FallbackTransferTemplate]) -> [BedBoardSnapshot] {
        var out: [BedBoardSnapshot] = []
        for item in items {
            let derived = newBedBoardSnapshot(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveBedBoardSnapshot(_ item: BedBoardSnapshot) -> Double {
        return fallbackTransferTemplateWeight(5, active: true)
    }
}
