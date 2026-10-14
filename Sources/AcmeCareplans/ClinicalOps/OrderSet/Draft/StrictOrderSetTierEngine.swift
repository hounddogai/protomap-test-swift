import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the strict order set tier calculation.
    protocol StrictOrderSetTierModifier {
        func describe() -> String
        func adjust(_ item: StrictOrderSetTier, value: Double) -> Double
    }

    final class PercentStrictOrderSetTierAdjuster: StrictOrderSetTierModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictOrderSetTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStrictOrderSetTierAdjuster: StrictOrderSetTierModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictOrderSetTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredStrictOrderSetTierAdjuster: StrictOrderSetTierModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictOrderSetTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapStrictOrderSetTierAdjuster: StrictOrderSetTierModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictOrderSetTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict order set tier steps in order and keeps a trace of each.
    final class StrictOrderSetTierEngine {
        var steps: [any StrictOrderSetTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictOrderSetTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictOrderSetTier) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictOrderSetTierModifier = steps[index]
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

        func evaluateAll(_ items: [StrictOrderSetTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictOrderSetTierEngine() -> StrictOrderSetTierEngine {
        return StrictOrderSetTierEngine(
            steps: [
                PercentStrictOrderSetTierAdjuster(percent: 15.5),
                MinimumStrictOrderSetTierAdjuster(minimum: 0.4),
                TieredStrictOrderSetTierAdjuster(
                    bounds: [3276.0, 3340.0, 5432.0, 5515.0],
                    rates: [0.84, 1.03, 1.03, 0.94]
                ),
                CapStrictOrderSetTierAdjuster(cap: 48254.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 55634.4
        )
    }
}
