import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferForecastsForDraft(_ items: [TransferForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveTransferDraftsFromForecast(_ items: [TransferForecast]) -> [TransferDraft] {
        var out: [TransferDraft] = []
        for item in items {
            let derived = newTransferDraft(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeTransferDraft(_ item: TransferDraft) -> String {
        return classifyTransferEstimate(item.measuredValue())
    }
}
