import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist window calculation.
    protocol WorklistWindowModifier {
        func describe() -> String
        func adjust(_ item: WorklistWindow, value: Double) -> Double
    }

    final class MinimumWorklistWindowAdjuster: WorklistWindowModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWorklistWindowAdjuster: WorklistWindowModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWorklistWindowAdjuster: WorklistWindowModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWorklistWindowAdjuster: WorklistWindowModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredWorklistWindowAdjuster: WorklistWindowModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the worklist window steps in order and keeps a trace of each.
    final class WorklistWindowEngine {
        var steps: [any WorklistWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WorklistWindow) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WorklistWindowModifier = steps[index]
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

        func evaluateAll(_ items: [WorklistWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWorklistWindowEngine() -> WorklistWindowEngine {
        return WorklistWindowEngine(
            steps: [
                MinimumWorklistWindowAdjuster(minimum: 3.9),
                PercentWorklistWindowAdjuster(percent: -1.3),
                CapWorklistWindowAdjuster(cap: 33589.0),
                RoundingWorklistWindowAdjuster(step: 0.1),
                TieredWorklistWindowAdjuster(bounds: [6889.0, 7392.0], rates: [1.05, 1.12]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 25806.6
        )
    }
}
