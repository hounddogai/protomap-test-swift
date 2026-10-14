import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set window calculation.
    protocol OrderSetWindowStep {
        func describe() -> String
        func adjust(_ item: OrderSetWindow, value: Double) -> Double
    }

    final class MinimumOrderSetWindowAdjuster: OrderSetWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentOrderSetWindowAdjuster: OrderSetWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapOrderSetWindowAdjuster: OrderSetWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the order set window steps in order and keeps a trace of each.
    final class OrderSetWindowEngine {
        var steps: [any OrderSetWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OrderSetWindow) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetWindowStep = steps[index]
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

        func evaluateAll(_ items: [OrderSetWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOrderSetWindowEngine() -> OrderSetWindowEngine {
        return OrderSetWindowEngine(
            steps: [
                MinimumOrderSetWindowAdjuster(minimum: 31.6),
                PercentOrderSetWindowAdjuster(percent: 4.7),
                CapOrderSetWindowAdjuster(cap: 31780.0),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 52329.1
        )
    }
}
