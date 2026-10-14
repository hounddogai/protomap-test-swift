import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution override calculation.
    protocol SubstitutionOverrideFactor {
        func describe() -> String
        func adjust(_ item: SubstitutionOverride, value: Double) -> Double
    }

    final class PercentSubstitutionOverrideAdjuster: SubstitutionOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSubstitutionOverrideAdjuster: SubstitutionOverrideFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SubstitutionOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumSubstitutionOverrideAdjuster: SubstitutionOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the substitution override steps in order and keeps a trace of each.
    final class SubstitutionOverrideEngine {
        var steps: [any SubstitutionOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SubstitutionOverride) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SubstitutionOverrideFactor = steps[index]
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

        func evaluateAll(_ items: [SubstitutionOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSubstitutionOverrideEngine() -> SubstitutionOverrideEngine {
        return SubstitutionOverrideEngine(
            steps: [
                PercentSubstitutionOverrideAdjuster(percent: -19.2),
                TieredSubstitutionOverrideAdjuster(bounds: [523.0, 5259.0, 7489.0], rates: [1.05, 1.15, 0.89]),
                MinimumSubstitutionOverrideAdjuster(minimum: 9.5),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 88929.2
        )
    }
}
