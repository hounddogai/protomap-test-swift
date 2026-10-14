import AcmePlatform
import Foundation

extension BedManagement {
    static func tieredTransferBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a tiered transfer bundle code in its canonical TTB- form.
    static func normalizeTieredTransferBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TTB-") {
            return clean
        }
        return "TTB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredTransferBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredTransferBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-transfer-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
