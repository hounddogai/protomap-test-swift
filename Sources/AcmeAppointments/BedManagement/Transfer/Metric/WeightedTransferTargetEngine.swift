import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the weighted transfer target calculation.
    protocol WeightedTransferTargetModifier {
        func describe() -> String
        func adjust(_ item: WeightedTransferTarget, value: Double) -> Double
    }

    final class CapWeightedTransferTargetAdjuster: WeightedTransferTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedTransferTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumWeightedTransferTargetAdjuster: WeightedTransferTargetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedTransferTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWeightedTransferTargetAdjuster: WeightedTransferTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedTransferTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LocaleWeightedTransferTargetAdjuster: WeightedTransferTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: WeightedTransferTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted transfer target steps in order and keeps a trace of each.
    final class WeightedTransferTargetEngine {
        var steps: [any WeightedTransferTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedTransferTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedTransferTarget) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [WeightedTransferTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedTransferTargetEngine() -> WeightedTransferTargetEngine {
        return WeightedTransferTargetEngine(
            steps: [
                CapWeightedTransferTargetAdjuster(cap: 18159.0),
                MinimumWeightedTransferTargetAdjuster(minimum: 48.4),
                TieredWeightedTransferTargetAdjuster(
                    bounds: [3783.0, 4980.0, 6016.0, 8919.0],
                    rates: [0.85, 0.84, 0.87, 1.15]
                ),
                LocaleWeightedTransferTargetAdjuster(factors: ["west": 0.75, "retail": 0.96]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 54605.8
        )
    }
}
