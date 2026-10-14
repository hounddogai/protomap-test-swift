import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result threshold calculation.
    protocol ResultThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: ResultThreshold, value: Double) -> Double
    }

    final class MinimumResultThresholdAdjuster: ResultThresholdAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ResultThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ResultThresholdMinimumOffsetAdjuster: ResultThresholdAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: ResultThreshold, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class CapResultThresholdAdjuster: ResultThresholdAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ResultThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedResultThresholdAdjuster: ResultThresholdAdjuster {
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

        func adjust(_ item: ResultThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingResultThresholdAdjuster: ResultThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the result threshold steps in order and keeps a trace of each.
    final class ResultThresholdEngine {
        var steps: [any ResultThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ResultThreshold) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [ResultThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultResultThresholdEngine(_ flags: Kit.Flags.Registry) -> ResultThresholdEngine {
        return ResultThresholdEngine(
            steps: [
                MinimumResultThresholdAdjuster(minimum: 27.0),
                ResultThresholdMinimumOffsetAdjuster(weight: 0.32),
                CapResultThresholdAdjuster(cap: 45137.0),
                FlaggedResultThresholdAdjuster(flags: flags, flag: "result-threshold-rolling", percent: 1.4),
                RoundingResultThresholdAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 98092.5
        )
    }
}
