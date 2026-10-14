import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted courier exception calculation.
    protocol WeightedCourierExceptionStep {
        func describe() -> String
        func adjust(_ item: WeightedCourierException, value: Double) -> Double
    }

    final class SegmentWeightedCourierExceptionAdjuster: WeightedCourierExceptionStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: WeightedCourierException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumWeightedCourierExceptionAdjuster: WeightedCourierExceptionStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedCourierException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWeightedCourierExceptionAdjuster: WeightedCourierExceptionStep {
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

        func adjust(_ item: WeightedCourierException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted courier exception steps in order and keeps a trace of each.
    final class WeightedCourierExceptionEngine {
        var steps: [any WeightedCourierExceptionStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedCourierExceptionStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedCourierException) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [WeightedCourierException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedCourierExceptionEngine(_ flags: Kit.Flags.Registry) -> WeightedCourierExceptionEngine {
        return WeightedCourierExceptionEngine(
            steps: [
                SegmentWeightedCourierExceptionAdjuster(factors: ["north": 1.36]),
                MinimumWeightedCourierExceptionAdjuster(minimum: 10.2),
                FlaggedWeightedCourierExceptionAdjuster(
                    flags: flags,
                    flag: "weighted-courier-exception-scheduled",
                    percent: -0.3
                ),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 21038.1
        )
    }
}
