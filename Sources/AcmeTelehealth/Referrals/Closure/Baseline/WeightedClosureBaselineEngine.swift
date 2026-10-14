import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted closure baseline calculation.
    protocol WeightedClosureBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedClosureBaseline, value: Double) -> Double
    }

    final class CapWeightedClosureBaselineAdjuster: WeightedClosureBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedClosureBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWeightedClosureBaselineAdjuster: WeightedClosureBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedClosureBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumWeightedClosureBaselineAdjuster: WeightedClosureBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedClosureBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted closure baseline steps in order and keeps a trace of each.
    final class WeightedClosureBaselineEngine {
        var steps: [any WeightedClosureBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedClosureBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedClosureBaseline) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [WeightedClosureBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedClosureBaselineEngine() -> WeightedClosureBaselineEngine {
        return WeightedClosureBaselineEngine(
            steps: [
                CapWeightedClosureBaselineAdjuster(cap: 17627.0),
                TieredWeightedClosureBaselineAdjuster(bounds: [488.0, 3464.0, 3874.0], rates: [0.83, 1.14, 0.97]),
                MinimumWeightedClosureBaselineAdjuster(minimum: 1.6),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 80917.8
        )
    }
}
