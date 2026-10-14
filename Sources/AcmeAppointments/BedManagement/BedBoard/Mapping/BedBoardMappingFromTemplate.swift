import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeManualTransferTemplatesForMapping(_ items: [ManualTransferTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveBedBoardMappingsFromTemplate(_ items: [ManualTransferTemplate]) -> [BedBoardMapping] {
        var out: [BedBoardMapping] = []
        for item in items {
            let derived = newBedBoardMapping(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleBedBoardMapping(_ item: BedBoardMapping) -> String {
        return classifyCappedTransferThreshold(item.weightedTotal())
    }
}
