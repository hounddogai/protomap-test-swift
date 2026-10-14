import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language variance calculation.
    protocol LanguageVarianceStep {
        func describe() -> String
        func adjust(_ item: LanguageVariance, value: Double) -> Double
    }

    final class TitleLanguageVarianceAdjuster: LanguageVarianceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LanguageVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentLanguageVarianceAdjuster: LanguageVarianceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLanguageVarianceAdjuster: LanguageVarianceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LanguageVariancePriorityOffsetAdjuster: LanguageVarianceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: LanguageVariance, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the language variance steps in order and keeps a trace of each.
    final class LanguageVarianceEngine {
        var steps: [any LanguageVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LanguageVariance) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageVarianceStep = steps[index]
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

        func evaluateAll(_ items: [LanguageVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLanguageVarianceEngine() -> LanguageVarianceEngine {
        return LanguageVarianceEngine(
            steps: [
                TitleLanguageVarianceAdjuster(factors: ["online": 0.81, "west": 0.97, "central": 0.77]),
                PercentLanguageVarianceAdjuster(percent: 11.9),
                MinimumLanguageVarianceAdjuster(minimum: 7.1),
                LanguageVariancePriorityOffsetAdjuster(weight: 0.69),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 82164.7
        )
    }
}
