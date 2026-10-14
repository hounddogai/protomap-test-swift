import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending statement group calculation.
    protocol PendingStatementGroupStep {
        func describe() -> String
        func adjust(_ item: PendingStatementGroup, value: Double) -> Double
    }

    final class RoundingPendingStatementGroupAdjuster: PendingStatementGroupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingStatementGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPendingStatementGroupAdjuster: PendingStatementGroupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingStatementGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LocalePendingStatementGroupAdjuster: PendingStatementGroupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: PendingStatementGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending statement group steps in order and keeps a trace of each.
    final class PendingStatementGroupEngine {
        var steps: [any PendingStatementGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingStatementGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingStatementGroup) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [PendingStatementGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingStatementGroupEngine() -> PendingStatementGroupEngine {
        return PendingStatementGroupEngine(
            steps: [
                RoundingPendingStatementGroupAdjuster(step: 0.25),
                TieredPendingStatementGroupAdjuster(bounds: [4932.0, 6261.0], rates: [1.04, 0.87]),
                LocalePendingStatementGroupAdjuster(factors: ["north": 0.85, "retail": 1.11]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 70571.2
        )
    }
}
