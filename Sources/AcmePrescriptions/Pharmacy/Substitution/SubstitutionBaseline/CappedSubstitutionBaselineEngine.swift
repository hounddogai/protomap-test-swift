import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the capped substitution baseline calculation.
    protocol CappedSubstitutionBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: CappedSubstitutionBaseline, value: Double) -> Double
    }

    final class MinimumCappedSubstitutionBaselineAdjuster: CappedSubstitutionBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedSubstitutionBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCappedSubstitutionBaselineAdjuster: CappedSubstitutionBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedSubstitutionBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCappedSubstitutionBaselineAdjuster: CappedSubstitutionBaselineAdjuster {
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

        func adjust(_ item: CappedSubstitutionBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCappedSubstitutionBaselineAdjuster: CappedSubstitutionBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedSubstitutionBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryCappedSubstitutionBaselineAdjuster: CappedSubstitutionBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: CappedSubstitutionBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the capped substitution baseline steps in order and keeps a trace of each.
    final class CappedSubstitutionBaselineEngine {
        var steps: [any CappedSubstitutionBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedSubstitutionBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedSubstitutionBaseline) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [CappedSubstitutionBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedSubstitutionBaselineEngine(_ flags: Kit.Flags.Registry) -> CappedSubstitutionBaselineEngine {
        return CappedSubstitutionBaselineEngine(
            steps: [
                MinimumCappedSubstitutionBaselineAdjuster(minimum: 44.9),
                RoundingCappedSubstitutionBaselineAdjuster(step: 1.0),
                FlaggedCappedSubstitutionBaselineAdjuster(
                    flags: flags,
                    flag: "capped-substitution-baseline-capped",
                    percent: 9.3
                ),
                TieredCappedSubstitutionBaselineAdjuster(bounds: [5245.0, 9284.0], rates: [0.92, 1.1]),
                CountryCappedSubstitutionBaselineAdjuster(factors: ["south": 0.78, "north": 0.78]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 65849.0
        )
    }
}
