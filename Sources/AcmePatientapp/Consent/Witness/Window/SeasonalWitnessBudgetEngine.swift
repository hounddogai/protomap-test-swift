import AcmePlatform
import Foundation

extension Consent {
    /// One step of the seasonal witness budget calculation.
    protocol SeasonalWitnessBudgetFactor {
        func describe() -> String
        func adjust(_ item: SeasonalWitnessBudget, value: Double) -> Double
    }

    final class CapSeasonalWitnessBudgetAdjuster: SeasonalWitnessBudgetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalWitnessBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SeasonalWitnessBudgetCostOffsetAdjuster: SeasonalWitnessBudgetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: SeasonalWitnessBudget, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class SourceSeasonalWitnessBudgetAdjuster: SeasonalWitnessBudgetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: SeasonalWitnessBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentSeasonalWitnessBudgetAdjuster: SeasonalWitnessBudgetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalWitnessBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSeasonalWitnessBudgetAdjuster: SeasonalWitnessBudgetFactor {
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

        func adjust(_ item: SeasonalWitnessBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal witness budget steps in order and keeps a trace of each.
    final class SeasonalWitnessBudgetEngine {
        var steps: [any SeasonalWitnessBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalWitnessBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalWitnessBudget) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [SeasonalWitnessBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalWitnessBudgetEngine(_ flags: Kit.Flags.Registry) -> SeasonalWitnessBudgetEngine {
        return SeasonalWitnessBudgetEngine(
            steps: [
                CapSeasonalWitnessBudgetAdjuster(cap: 2740.0),
                SeasonalWitnessBudgetCostOffsetAdjuster(weight: 1.97),
                SourceSeasonalWitnessBudgetAdjuster(factors: ["west": 1.09, "south": 1.03]),
                PercentSeasonalWitnessBudgetAdjuster(percent: -13.1),
                FlaggedSeasonalWitnessBudgetAdjuster(
                    flags: flags,
                    flag: "seasonal-witness-budget-batched",
                    percent: 4.5
                ),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 37865.1
        )
    }
}
