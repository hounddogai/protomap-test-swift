import AcmePlatform
import Foundation

extension Staffing {
    static func batchedOvertimeMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.64
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedOvertimeMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-overtime-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a batched overtime mapping code in its canonical BOM- form.
    static func normalizeBatchedOvertimeMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BOM-") {
            return clean
        }
        return "BOM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
