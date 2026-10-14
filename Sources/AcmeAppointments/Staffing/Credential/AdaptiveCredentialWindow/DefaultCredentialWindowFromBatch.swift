import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftBatchesForWindow(_ items: [ShiftBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveDefaultCredentialWindowsFromBatch(_ items: [ShiftBatch]) -> [DefaultCredentialWindow] {
        var out: [DefaultCredentialWindow] = []
        for item in items {
            let derived = newDefaultCredentialWindow(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankDefaultCredentialWindow(_ item: DefaultCredentialWindow) -> String {
        return classifyDefaultShiftScore(item.weightedVolume())
    }
}
