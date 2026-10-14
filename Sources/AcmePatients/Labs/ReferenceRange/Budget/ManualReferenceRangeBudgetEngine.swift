import AcmePlatform
import Foundation

extension Labs {
    /// One step of the manual reference range budget calculation.
    protocol ManualReferenceRangeBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: ManualReferenceRangeBudget, value: Double) -> Double
    }

    final class TieredManualReferenceRangeBudgetAdjuster: ManualReferenceRangeBudgetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualReferenceRangeBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedManualReferenceRangeBudgetAdjuster: ManualReferenceRangeBudgetAdjuster {
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

        func adjust(_ item: ManualReferenceRangeBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualReferenceRangeBudgetAdjuster: ManualReferenceRangeBudgetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualReferenceRangeBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumManualReferenceRangeBudgetAdjuster: ManualReferenceRangeBudgetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualReferenceRangeBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualReferenceRangeBudgetAdjuster: ManualReferenceRangeBudgetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualReferenceRangeBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual reference range budget steps in order and keeps a trace of each.
    final class ManualReferenceRangeBudgetEngine {
        var steps: [any ManualReferenceRangeBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualReferenceRangeBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualReferenceRangeBudget) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ManualReferenceRangeBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualReferenceRangeBudgetEngine(_ flags: Kit.Flags.Registry) -> ManualReferenceRangeBudgetEngine {
        return ManualReferenceRangeBudgetEngine(
            steps: [
                TieredManualReferenceRangeBudgetAdjuster(
                    bounds: [485.0, 3687.0, 4886.0, 9378.0],
                    rates: [1.2, 0.87, 0.84, 1.07]
                ),
                FlaggedManualReferenceRangeBudgetAdjuster(
                    flags: flags,
                    flag: "manual-reference-range-budget-scheduled",
                    percent: -5.7
                ),
                RoundingManualReferenceRangeBudgetAdjuster(step: 1.0),
                MinimumManualReferenceRangeBudgetAdjuster(minimum: 37.7),
                PercentManualReferenceRangeBudgetAdjuster(percent: 0.7),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 63783.2
        )
    }
}
