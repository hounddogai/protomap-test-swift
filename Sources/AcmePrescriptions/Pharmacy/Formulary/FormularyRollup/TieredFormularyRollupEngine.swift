import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the tiered formulary rollup calculation.
    protocol TieredFormularyRollupFactor {
        func describe() -> String
        func adjust(_ item: TieredFormularyRollup, value: Double) -> Double
    }

    final class MinimumTieredFormularyRollupAdjuster: TieredFormularyRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredFormularyRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredFormularyRollupAmountOffsetAdjuster: TieredFormularyRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: TieredFormularyRollup, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class CapTieredFormularyRollupAdjuster: TieredFormularyRollupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredFormularyRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingTieredFormularyRollupAdjuster: TieredFormularyRollupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredFormularyRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryTieredFormularyRollupAdjuster: TieredFormularyRollupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: TieredFormularyRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredFormularyRollupAdjuster: TieredFormularyRollupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredFormularyRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered formulary rollup steps in order and keeps a trace of each.
    final class TieredFormularyRollupEngine {
        var steps: [any TieredFormularyRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredFormularyRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredFormularyRollup) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredFormularyRollupFactor = steps[index]
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

        func evaluateAll(_ items: [TieredFormularyRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredFormularyRollupEngine() -> TieredFormularyRollupEngine {
        return TieredFormularyRollupEngine(
            steps: [
                MinimumTieredFormularyRollupAdjuster(minimum: 29.2),
                TieredFormularyRollupAmountOffsetAdjuster(weight: 1.38),
                CapTieredFormularyRollupAdjuster(cap: 8353.0),
                RoundingTieredFormularyRollupAdjuster(step: 1.0),
                CountryTieredFormularyRollupAdjuster(factors: ["west": 1.31]),
                TieredTieredFormularyRollupAdjuster(
                    bounds: [2499.0, 6466.0, 6622.0, 6979.0],
                    rates: [1.11, 0.95, 0.85, 1.08]
                ),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 34624.6
        )
    }
}
