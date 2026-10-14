import AcmePlatform
import Foundation

extension Labs {
    /// One step of the strict courier policy calculation.
    protocol StrictCourierPolicyStep {
        func describe() -> String
        func adjust(_ item: StrictCourierPolicy, value: Double) -> Double
    }

    final class LocaleStrictCourierPolicyAdjuster: StrictCourierPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: StrictCourierPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingStrictCourierPolicyAdjuster: StrictCourierPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictCourierPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StrictCourierPolicyDurationMinutesOffsetAdjuster: StrictCourierPolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: StrictCourierPolicy, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class PercentStrictCourierPolicyAdjuster: StrictCourierPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictCourierPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictCourierPolicyAdjuster: StrictCourierPolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictCourierPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict courier policy steps in order and keeps a trace of each.
    final class StrictCourierPolicyEngine {
        var steps: [any StrictCourierPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCourierPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictCourierPolicy) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictCourierPolicyStep = steps[index]
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

        func evaluateAll(_ items: [StrictCourierPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictCourierPolicyEngine() -> StrictCourierPolicyEngine {
        return StrictCourierPolicyEngine(
            steps: [
                LocaleStrictCourierPolicyAdjuster(factors: ["online": 1.2]),
                RoundingStrictCourierPolicyAdjuster(step: 1.0),
                StrictCourierPolicyDurationMinutesOffsetAdjuster(weight: 1.21),
                PercentStrictCourierPolicyAdjuster(percent: 8.5),
                TieredStrictCourierPolicyAdjuster(bounds: [45.0, 1365.0, 5414.0], rates: [1.2, 0.94, 1.14]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 20965.5
        )
    }
}
