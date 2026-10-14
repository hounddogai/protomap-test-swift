import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool score calculation.
    protocol FloatPoolScoreAdjuster {
        func describe() -> String
        func adjust(_ item: FloatPoolScore, value: Double) -> Double
    }

    final class MinimumFloatPoolScoreAdjuster: FloatPoolScoreAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFloatPoolScoreAdjuster: FloatPoolScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FloatPoolScoreCostOffsetAdjuster: FloatPoolScoreAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: FloatPoolScore, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class FlaggedFloatPoolScoreAdjuster: FloatPoolScoreAdjuster {
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

        func adjust(_ item: FloatPoolScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelFloatPoolScoreAdjuster: FloatPoolScoreAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: FloatPoolScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the float pool score steps in order and keeps a trace of each.
    final class FloatPoolScoreEngine {
        var steps: [any FloatPoolScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FloatPoolScore) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolScoreAdjuster = steps[index]
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

        func evaluateAll(_ items: [FloatPoolScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFloatPoolScoreEngine(_ flags: Kit.Flags.Registry) -> FloatPoolScoreEngine {
        return FloatPoolScoreEngine(
            steps: [
                MinimumFloatPoolScoreAdjuster(minimum: 40.6),
                RoundingFloatPoolScoreAdjuster(step: 0.1),
                FloatPoolScoreCostOffsetAdjuster(weight: 0.94),
                FlaggedFloatPoolScoreAdjuster(flags: flags, flag: "float-pool-score-lenient", percent: -8.5),
                LabelFloatPoolScoreAdjuster(factors: ["east": 1.35, "retail": 1.21, "online": 0.94]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 60329.5
        )
    }
}
