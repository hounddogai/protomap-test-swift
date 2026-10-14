import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardSchedulesForRequest(_ items: [BedBoardSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualIsolationRequestsFromSchedule(_ items: [BedBoardSchedule]) -> [ManualIsolationRequest] {
        var out: [ManualIsolationRequest] = []
        for item in items {
            let derived = newManualIsolationRequest(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankManualIsolationRequest(_ item: ManualIsolationRequest) -> Double {
        return cappedBedBoardGroupWeight(9, active: true)
    }
}
