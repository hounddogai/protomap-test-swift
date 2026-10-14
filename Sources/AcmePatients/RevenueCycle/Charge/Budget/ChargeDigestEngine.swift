import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge digest calculation.
    protocol ChargeDigestStep {
        func describe() -> String
        func adjust(_ item: ChargeDigest, value: Double) -> Double
    }

    final class MinimumChargeDigestAdjuster: ChargeDigestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceChargeDigestAdjuster: ChargeDigestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ChargeDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapChargeDigestAdjuster: ChargeDigestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingChargeDigestAdjuster: ChargeDigestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedChargeDigestAdjuster: ChargeDigestStep {
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

        func adjust(_ item: ChargeDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge digest steps in order and keeps a trace of each.
    final class ChargeDigestEngine {
        var steps: [any ChargeDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ChargeDigest) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeDigestStep = steps[index]
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

        func evaluateAll(_ items: [ChargeDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultChargeDigestEngine(_ flags: Kit.Flags.Registry) -> ChargeDigestEngine {
        return ChargeDigestEngine(
            steps: [
                MinimumChargeDigestAdjuster(minimum: 13.0),
                SourceChargeDigestAdjuster(factors: ["central": 1.19, "east": 1.19, "north": 1.04]),
                CapChargeDigestAdjuster(cap: 4208.0),
                RoundingChargeDigestAdjuster(step: 0.25),
                FlaggedChargeDigestAdjuster(flags: flags, flag: "charge-digest-tiered", percent: 1.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 49912.4
        )
    }
}
