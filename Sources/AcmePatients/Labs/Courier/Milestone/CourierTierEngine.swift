import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier tier calculation.
    protocol CourierTierStep {
        func describe() -> String
        func adjust(_ item: CourierTier, value: Double) -> Double
    }

    final class CourierTierBatchSizeOffsetAdjuster: CourierTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: CourierTier, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class SourceCourierTierAdjuster: CourierTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CourierTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCourierTierAdjuster: CourierTierStep {
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

        func adjust(_ item: CourierTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCourierTierAdjuster: CourierTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCourierTierAdjuster: CourierTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the courier tier steps in order and keeps a trace of each.
    final class CourierTierEngine {
        var steps: [any CourierTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CourierTier) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CourierTierStep = steps[index]
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

        func evaluateAll(_ items: [CourierTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCourierTierEngine(_ flags: Kit.Flags.Registry) -> CourierTierEngine {
        return CourierTierEngine(
            steps: [
                CourierTierBatchSizeOffsetAdjuster(weight: 0.39),
                SourceCourierTierAdjuster(factors: ["retail": 1.22]),
                FlaggedCourierTierAdjuster(flags: flags, flag: "courier-tier-pending", percent: -9.6),
                RoundingCourierTierAdjuster(step: 1.0),
                MinimumCourierTierAdjuster(minimum: 46.5),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 4781.3
        )
    }
}
