import AcmePlatform
import Foundation

extension ClinicalOps {
    static func batchedCareProtocolPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func batchedCareProtocolPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedCareProtocolPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-care-protocol-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a batched care protocol plan code in its canonical BCPP- form.
    static func normalizeBatchedCareProtocolPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BCPP-") {
            return clean
        }
        return "BCPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
