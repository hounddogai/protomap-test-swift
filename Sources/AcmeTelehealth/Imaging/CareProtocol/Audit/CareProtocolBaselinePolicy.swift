import AcmePlatform
import Foundation

extension Imaging {
    static func careProtocolBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func careProtocolBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
