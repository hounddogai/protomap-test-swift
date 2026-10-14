import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language batch calculation.
    protocol LanguageBatchStep {
        func describe() -> String
        func adjust(_ item: LanguageBatch, value: Double) -> Double
    }

    final class FlaggedLanguageBatchAdjuster: LanguageBatchStep {
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

        func adjust(_ item: LanguageBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LanguageBatchAcuityOffsetAdjuster: LanguageBatchStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: LanguageBatch, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class PercentLanguageBatchAdjuster: LanguageBatchStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLanguageBatchAdjuster: LanguageBatchStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguageBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingLanguageBatchAdjuster: LanguageBatchStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguageBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CategoryLanguageBatchAdjuster: LanguageBatchStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: LanguageBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the language batch steps in order and keeps a trace of each.
    final class LanguageBatchEngine {
        var steps: [any LanguageBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LanguageBatch) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageBatchStep = steps[index]
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

        func evaluateAll(_ items: [LanguageBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLanguageBatchEngine(_ flags: Kit.Flags.Registry) -> LanguageBatchEngine {
        return LanguageBatchEngine(
            steps: [
                FlaggedLanguageBatchAdjuster(flags: flags, flag: "language-batch-lenient", percent: 3.5),
                LanguageBatchAcuityOffsetAdjuster(weight: 1.31),
                PercentLanguageBatchAdjuster(percent: -13.9),
                TieredLanguageBatchAdjuster(bounds: [1499.0, 3460.0, 3582.0, 4724.0], rates: [0.81, 1.1, 1.1, 1.13]),
                RoundingLanguageBatchAdjuster(step: 0.1),
                CategoryLanguageBatchAdjuster(factors: ["retail": 1.12, "central": 0.88]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 66854.4
        )
    }
}
