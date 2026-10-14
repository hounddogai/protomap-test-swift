import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift rule calculation.
    protocol ShiftRuleStep {
        func describe() -> String
        func adjust(_ item: ShiftRule, value: Double) -> Double
    }

    final class MinimumShiftRuleAdjuster: ShiftRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ShiftRuleRevisionOffsetAdjuster: ShiftRuleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: ShiftRule, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class PercentShiftRuleAdjuster: ShiftRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the shift rule steps in order and keeps a trace of each.
    final class ShiftRuleEngine {
        var steps: [any ShiftRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ShiftRule) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftRuleStep = steps[index]
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

        func evaluateAll(_ items: [ShiftRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultShiftRuleEngine() -> ShiftRuleEngine {
        return ShiftRuleEngine(
            steps: [
                MinimumShiftRuleAdjuster(minimum: 38.6),
                ShiftRuleRevisionOffsetAdjuster(weight: 1.56),
                PercentShiftRuleAdjuster(percent: -2.5),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 71535.0
        )
    }
}
