import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding target calculation.
    protocol RoundingTargetStep {
        func describe() -> String
        func adjust(_ item: RoundingTarget, value: Double) -> Double
    }

    final class PercentRoundingTargetAdjuster: RoundingTargetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRoundingTargetAdjuster: RoundingTargetStep {
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

        func adjust(_ item: RoundingTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRoundingTargetAdjuster: RoundingTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelRoundingTargetAdjuster: RoundingTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RoundingTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingTargetRetriesOffsetAdjuster: RoundingTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: RoundingTarget, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    /// Runs the rounding target steps in order and keeps a trace of each.
    final class RoundingTargetEngine {
        var steps: [any RoundingTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RoundingTarget) -> Double {
            var current = item.projectedVolume()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RoundingTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRoundingTargetEngine(_ flags: Kit.Flags.Registry) -> RoundingTargetEngine {
        return RoundingTargetEngine(
            steps: [
                PercentRoundingTargetAdjuster(percent: 14.8),
                FlaggedRoundingTargetAdjuster(flags: flags, flag: "rounding-target-adaptive", percent: 8.9),
                CapRoundingTargetAdjuster(cap: 44685.0),
                LabelRoundingTargetAdjuster(factors: ["south": 1.14, "east": 1.26]),
                RoundingTargetRetriesOffsetAdjuster(weight: 1.41),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 83224.0
        )
    }
}
