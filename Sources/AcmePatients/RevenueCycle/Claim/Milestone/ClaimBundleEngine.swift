import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim bundle calculation.
    protocol ClaimBundleFactor {
        func describe() -> String
        func adjust(_ item: ClaimBundle, value: Double) -> Double
    }

    final class RoundingClaimBundleAdjuster: ClaimBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumClaimBundleAdjuster: ClaimBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapClaimBundleAdjuster: ClaimBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ClaimBundleLimitOffsetAdjuster: ClaimBundleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: ClaimBundle, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class FlaggedClaimBundleAdjuster: ClaimBundleFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: ClaimBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredClaimBundleAdjuster: ClaimBundleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the claim bundle steps in order and keeps a trace of each.
    final class ClaimBundleEngine {
        var steps: [any ClaimBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClaimBundle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimBundleFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [ClaimBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClaimBundleEngine(_ flags: Kit.Flags.Registry) -> ClaimBundleEngine {
        return ClaimBundleEngine(
            steps: [
                RoundingClaimBundleAdjuster(step: 0.05),
                MinimumClaimBundleAdjuster(minimum: 5.0),
                CapClaimBundleAdjuster(cap: 17639.0),
                ClaimBundleLimitOffsetAdjuster(weight: 0.19),
                FlaggedClaimBundleAdjuster(flags: flags, flag: "claim-bundle-primary", percent: -0.1),
                TieredClaimBundleAdjuster(bounds: [6063.0, 6959.0], rates: [0.91, 1.18]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 62090.4
        )
    }
}
