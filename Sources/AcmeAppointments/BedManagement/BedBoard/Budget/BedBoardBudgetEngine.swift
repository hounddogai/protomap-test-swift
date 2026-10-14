import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board budget calculation.
    protocol BedBoardBudgetFactor {
        func describe() -> String
        func adjust(_ item: BedBoardBudget, value: Double) -> Double
    }

    final class RoundingBedBoardBudgetAdjuster: BedBoardBudgetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumBedBoardBudgetAdjuster: BedBoardBudgetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredBedBoardBudgetAdjuster: BedBoardBudgetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedBedBoardBudgetAdjuster: BedBoardBudgetFactor {
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

        func adjust(_ item: BedBoardBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the bed board budget steps in order and keeps a trace of each.
    final class BedBoardBudgetEngine {
        var steps: [any BedBoardBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BedBoardBudget) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardBudgetFactor = steps[index]
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

        func evaluateAll(_ items: [BedBoardBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBedBoardBudgetEngine(_ flags: Kit.Flags.Registry) -> BedBoardBudgetEngine {
        return BedBoardBudgetEngine(
            steps: [
                RoundingBedBoardBudgetAdjuster(step: 5.0),
                MinimumBedBoardBudgetAdjuster(minimum: 29.8),
                TieredBedBoardBudgetAdjuster(
                    bounds: [3067.0, 6675.0, 8425.0, 9609.0],
                    rates: [1.14, 0.99, 0.88, 1.07]
                ),
                FlaggedBedBoardBudgetAdjuster(flags: flags, flag: "bed-board-budget-capped", percent: 5.0),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 64470.8
        )
    }
}
