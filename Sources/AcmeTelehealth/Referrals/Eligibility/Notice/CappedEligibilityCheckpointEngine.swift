import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped eligibility checkpoint calculation.
    protocol CappedEligibilityCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: CappedEligibilityCheckpoint, value: Double) -> Double
    }

    final class TitleCappedEligibilityCheckpointAdjuster: CappedEligibilityCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CappedEligibilityCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCappedEligibilityCheckpointAdjuster: CappedEligibilityCheckpointAdjuster {
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

        func adjust(_ item: CappedEligibilityCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCappedEligibilityCheckpointAdjuster: CappedEligibilityCheckpointAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedEligibilityCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedEligibilityCheckpointAdjuster: CappedEligibilityCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedEligibilityCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedEligibilityCheckpointAdjuster: CappedEligibilityCheckpointAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedEligibilityCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCappedEligibilityCheckpointAdjuster: CappedEligibilityCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedEligibilityCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped eligibility checkpoint steps in order and keeps a trace of each.
    final class CappedEligibilityCheckpointEngine {
        var steps: [any CappedEligibilityCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedEligibilityCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedEligibilityCheckpoint) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedEligibilityCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedEligibilityCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedEligibilityCheckpointEngine(_ flags: Kit.Flags.Registry) -> CappedEligibilityCheckpointEngine {
        return CappedEligibilityCheckpointEngine(
            steps: [
                TitleCappedEligibilityCheckpointAdjuster(factors: ["west": 1.38, "retail": 1.32]),
                FlaggedCappedEligibilityCheckpointAdjuster(
                    flags: flags,
                    flag: "capped-eligibility-checkpoint-manual",
                    percent: 3.6
                ),
                PercentCappedEligibilityCheckpointAdjuster(percent: 17.3),
                CapCappedEligibilityCheckpointAdjuster(cap: 5877.0),
                TieredCappedEligibilityCheckpointAdjuster(bounds: [1951.0, 6133.0, 6466.0], rates: [0.92, 1.09, 1.11]),
                RoundingCappedEligibilityCheckpointAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 86630.3
        )
    }
}
