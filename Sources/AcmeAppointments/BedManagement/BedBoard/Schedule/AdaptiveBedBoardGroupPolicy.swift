import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveBedBoardGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-bed-board-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a adaptive bed board group code in its canonical ABBG- form.
    static func normalizeAdaptiveBedBoardGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ABBG-") {
            return clean
        }
        return "ABBG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
