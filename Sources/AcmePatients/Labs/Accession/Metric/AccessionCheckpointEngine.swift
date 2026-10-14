import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession checkpoint calculation.
    protocol AccessionCheckpointStep {
        func describe() -> String
        func adjust(_ item: AccessionCheckpoint, value: Double) -> Double
    }

    final class TieredAccessionCheckpointAdjuster: AccessionCheckpointStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingAccessionCheckpointAdjuster: AccessionCheckpointStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapAccessionCheckpointAdjuster: AccessionCheckpointStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAccessionCheckpointAdjuster: AccessionCheckpointStep {
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

        func adjust(_ item: AccessionCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelAccessionCheckpointAdjuster: AccessionCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AccessionCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAccessionCheckpointAdjuster: AccessionCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the accession checkpoint steps in order and keeps a trace of each.
    final class AccessionCheckpointEngine {
        var steps: [any AccessionCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AccessionCheckpoint) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionCheckpointStep = steps[index]
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

        func evaluateAll(_ items: [AccessionCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAccessionCheckpointEngine(_ flags: Kit.Flags.Registry) -> AccessionCheckpointEngine {
        return AccessionCheckpointEngine(
            steps: [
                TieredAccessionCheckpointAdjuster(bounds: [2824.0, 5666.0], rates: [0.84, 0.83]),
                RoundingAccessionCheckpointAdjuster(step: 5.0),
                CapAccessionCheckpointAdjuster(cap: 18933.0),
                FlaggedAccessionCheckpointAdjuster(flags: flags, flag: "accession-checkpoint-scheduled", percent: 1.3),
                LabelAccessionCheckpointAdjuster(factors: ["north": 1.32]),
                PercentAccessionCheckpointAdjuster(percent: 0.6),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 59223.3
        )
    }
}
