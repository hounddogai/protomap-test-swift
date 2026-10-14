import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTransferPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("transfer-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeTransferPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
