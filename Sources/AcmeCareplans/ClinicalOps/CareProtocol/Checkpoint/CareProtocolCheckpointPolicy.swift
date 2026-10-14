import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a care protocol checkpoint code in its canonical CPC- form.
    static func normalizeCareProtocolCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPC-") {
            return clean
        }
        return "CPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
