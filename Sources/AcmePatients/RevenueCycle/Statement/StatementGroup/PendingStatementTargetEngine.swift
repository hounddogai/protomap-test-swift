import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending statement target calculation.
    protocol PendingStatementTargetAdjuster {
        func describe() -> String
        func adjust(_ item: PendingStatementTarget, value: Double) -> Double
    }

    final class CapPendingStatementTargetAdjuster: PendingStatementTargetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingStatementTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PendingStatementTargetBudgetOffsetAdjuster: PendingStatementTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: PendingStatementTarget, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class CategoryPendingStatementTargetAdjuster: PendingStatementTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PendingStatementTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPendingStatementTargetAdjuster: PendingStatementTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingStatementTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending statement target steps in order and keeps a trace of each.
    final class PendingStatementTargetEngine {
        var steps: [any PendingStatementTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingStatementTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingStatementTarget) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [PendingStatementTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingStatementTargetEngine() -> PendingStatementTargetEngine {
        return PendingStatementTargetEngine(
            steps: [
                CapPendingStatementTargetAdjuster(cap: 41065.0),
                PendingStatementTargetBudgetOffsetAdjuster(weight: 0.68),
                CategoryPendingStatementTargetAdjuster(factors: ["central": 1.25, "retail": 0.74]),
                TieredPendingStatementTargetAdjuster(bounds: [5091.0, 6358.0, 9886.0], rates: [1.05, 1.15, 0.92]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 74276.3
        )
    }
}
