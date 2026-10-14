import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the strict claim digest calculation.
    protocol StrictClaimDigestFactor {
        func describe() -> String
        func adjust(_ item: StrictClaimDigest, value: Double) -> Double
    }

    final class FlaggedStrictClaimDigestAdjuster: StrictClaimDigestFactor {
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

        func adjust(_ item: StrictClaimDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStrictClaimDigestAdjuster: StrictClaimDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictClaimDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStrictClaimDigestAdjuster: StrictClaimDigestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictClaimDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StrictClaimDigestCreatedAtOffsetAdjuster: StrictClaimDigestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: StrictClaimDigest, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class SegmentStrictClaimDigestAdjuster: StrictClaimDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: StrictClaimDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict claim digest steps in order and keeps a trace of each.
    final class StrictClaimDigestEngine {
        var steps: [any StrictClaimDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictClaimDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictClaimDigest) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictClaimDigestFactor = steps[index]
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

        func evaluateAll(_ items: [StrictClaimDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictClaimDigestEngine(_ flags: Kit.Flags.Registry) -> StrictClaimDigestEngine {
        return StrictClaimDigestEngine(
            steps: [
                FlaggedStrictClaimDigestAdjuster(flags: flags, flag: "strict-claim-digest-manual", percent: 3.8),
                MinimumStrictClaimDigestAdjuster(minimum: 49.5),
                CapStrictClaimDigestAdjuster(cap: 5777.0),
                StrictClaimDigestCreatedAtOffsetAdjuster(weight: 1.33),
                SegmentStrictClaimDigestAdjuster(factors: ["retail": 0.95]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 50519.0
        )
    }
}
