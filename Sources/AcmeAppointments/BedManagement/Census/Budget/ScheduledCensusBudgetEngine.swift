import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled census budget calculation.
    protocol ScheduledCensusBudgetStep {
        func describe() -> String
        func adjust(_ item: ScheduledCensusBudget, value: Double) -> Double
    }

    final class FlaggedScheduledCensusBudgetAdjuster: ScheduledCensusBudgetStep {
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

        func adjust(_ item: ScheduledCensusBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledCensusBudgetAdjuster: ScheduledCensusBudgetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledCensusBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapScheduledCensusBudgetAdjuster: ScheduledCensusBudgetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledCensusBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleScheduledCensusBudgetAdjuster: ScheduledCensusBudgetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ScheduledCensusBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumScheduledCensusBudgetAdjuster: ScheduledCensusBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledCensusBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledCensusBudgetAdjuster: ScheduledCensusBudgetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledCensusBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled census budget steps in order and keeps a trace of each.
    final class ScheduledCensusBudgetEngine {
        var steps: [any ScheduledCensusBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCensusBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledCensusBudget) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ScheduledCensusBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledCensusBudgetEngine(_ flags: Kit.Flags.Registry) -> ScheduledCensusBudgetEngine {
        return ScheduledCensusBudgetEngine(
            steps: [
                FlaggedScheduledCensusBudgetAdjuster(
                    flags: flags,
                    flag: "scheduled-census-budget-fallback",
                    percent: 7.5
                ),
                TieredScheduledCensusBudgetAdjuster(bounds: [2620.0, 3570.0, 4158.0], rates: [1.11, 1.07, 1.09]),
                CapScheduledCensusBudgetAdjuster(cap: 25311.0),
                LocaleScheduledCensusBudgetAdjuster(factors: ["west": 1.05, "east": 1.23]),
                MinimumScheduledCensusBudgetAdjuster(minimum: 20.1),
                RoundingScheduledCensusBudgetAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 75877.5
        )
    }
}
