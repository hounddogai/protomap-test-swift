import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal priority rule calculation.
    protocol SeasonalPriorityRuleFactor {
        func describe() -> String
        func adjust(_ item: SeasonalPriorityRule, value: Double) -> Double
    }

    final class RoundingSeasonalPriorityRuleAdjuster: SeasonalPriorityRuleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalPriorityRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSeasonalPriorityRuleAdjuster: SeasonalPriorityRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalPriorityRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapSeasonalPriorityRuleAdjuster: SeasonalPriorityRuleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalPriorityRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SeasonalPriorityRuleWindowDaysOffsetAdjuster: SeasonalPriorityRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: SeasonalPriorityRule, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the seasonal priority rule steps in order and keeps a trace of each.
    final class SeasonalPriorityRuleEngine {
        var steps: [any SeasonalPriorityRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalPriorityRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalPriorityRule) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalPriorityRuleFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalPriorityRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalPriorityRuleEngine() -> SeasonalPriorityRuleEngine {
        return SeasonalPriorityRuleEngine(
            steps: [
                RoundingSeasonalPriorityRuleAdjuster(step: 0.25),
                MinimumSeasonalPriorityRuleAdjuster(minimum: 49.7),
                CapSeasonalPriorityRuleAdjuster(cap: 16886.0),
                SeasonalPriorityRuleWindowDaysOffsetAdjuster(weight: 1.33),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 47827.5
        )
    }
}
