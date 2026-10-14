import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global alert tier calculation.
    protocol GlobalAlertTierFactor {
        func describe() -> String
        func adjust(_ item: GlobalAlertTier, value: Double) -> Double
    }

    final class TieredGlobalAlertTierAdjuster: GlobalAlertTierFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalAlertTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumGlobalAlertTierAdjuster: GlobalAlertTierFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalAlertTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingGlobalAlertTierAdjuster: GlobalAlertTierFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalAlertTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapGlobalAlertTierAdjuster: GlobalAlertTierFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalAlertTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleGlobalAlertTierAdjuster: GlobalAlertTierFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GlobalAlertTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global alert tier steps in order and keeps a trace of each.
    final class GlobalAlertTierEngine {
        var steps: [any GlobalAlertTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAlertTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalAlertTier) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalAlertTierFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalAlertTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalAlertTierEngine() -> GlobalAlertTierEngine {
        return GlobalAlertTierEngine(
            steps: [
                TieredGlobalAlertTierAdjuster(bounds: [5304.0, 6411.0], rates: [0.96, 0.96]),
                MinimumGlobalAlertTierAdjuster(minimum: 37.9),
                RoundingGlobalAlertTierAdjuster(step: 1.0),
                CapGlobalAlertTierAdjuster(cap: 32043.0),
                TitleGlobalAlertTierAdjuster(factors: ["west": 0.99, "north": 1.27]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 94544.4
        )
    }
}
