import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a global care gap allocation code in its canonical GCGA- form.
    static func normalizeGlobalCareGapAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GCGA-") {
            return clean
        }
        return "GCGA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalCareGapAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-care-gap-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
