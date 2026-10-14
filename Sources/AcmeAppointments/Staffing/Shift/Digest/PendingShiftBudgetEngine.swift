import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending shift budget calculation.
    protocol PendingShiftBudgetFactor {
        func describe() -> String
        func adjust(_ item: PendingShiftBudget, value: Double) -> Double
    }

    final class CapPendingShiftBudgetAdjuster: PendingShiftBudgetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingShiftBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPendingShiftBudgetAdjuster: PendingShiftBudgetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingShiftBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPendingShiftBudgetAdjuster: PendingShiftBudgetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingShiftBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending shift budget steps in order and keeps a trace of each.
    final class PendingShiftBudgetEngine {
        var steps: [any PendingShiftBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingShiftBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingShiftBudget) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingShiftBudgetFactor = steps[index]
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

        func evaluateAll(_ items: [PendingShiftBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingShiftBudgetEngine() -> PendingShiftBudgetEngine {
        return PendingShiftBudgetEngine(
            steps: [
                CapPendingShiftBudgetAdjuster(cap: 9729.0),
                TieredPendingShiftBudgetAdjuster(bounds: [9521.0, 9771.0], rates: [0.99, 0.98]),
                PercentPendingShiftBudgetAdjuster(percent: -19.7),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 34004.7
        )
    }
}
