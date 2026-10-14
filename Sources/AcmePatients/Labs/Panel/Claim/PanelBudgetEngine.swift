import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel budget calculation.
    protocol PanelBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: PanelBudget, value: Double) -> Double
    }

    final class MinimumPanelBudgetAdjuster: PanelBudgetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPanelBudgetAdjuster: PanelBudgetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PanelBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPanelBudgetAdjuster: PanelBudgetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the panel budget steps in order and keeps a trace of each.
    final class PanelBudgetEngine {
        var steps: [any PanelBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PanelBudget) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelBudgetAdjuster = steps[index]
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

        func evaluateAll(_ items: [PanelBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPanelBudgetEngine() -> PanelBudgetEngine {
        return PanelBudgetEngine(
            steps: [
                MinimumPanelBudgetAdjuster(minimum: 46.7),
                TieredPanelBudgetAdjuster(bounds: [1799.0, 8554.0], rates: [0.98, 0.9]),
                CapPanelBudgetAdjuster(cap: 41480.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 12770.2
        )
    }
}
