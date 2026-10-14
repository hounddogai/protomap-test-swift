import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the adaptive transfer tier calculation.
    protocol AdaptiveTransferTierStep {
        func describe() -> String
        func adjust(_ item: AdaptiveTransferTier, value: Double) -> Double
    }

    final class MinimumAdaptiveTransferTierAdjuster: AdaptiveTransferTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveTransferTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAdaptiveTransferTierAdjuster: AdaptiveTransferTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveTransferTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelAdaptiveTransferTierAdjuster: AdaptiveTransferTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AdaptiveTransferTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the adaptive transfer tier steps in order and keeps a trace of each.
    final class AdaptiveTransferTierEngine {
        var steps: [any AdaptiveTransferTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveTransferTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveTransferTier) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveTransferTierStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveTransferTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveTransferTierEngine() -> AdaptiveTransferTierEngine {
        return AdaptiveTransferTierEngine(
            steps: [
                MinimumAdaptiveTransferTierAdjuster(minimum: 33.6),
                TieredAdaptiveTransferTierAdjuster(bounds: [1488.0, 3396.0], rates: [1.08, 0.86]),
                LabelAdaptiveTransferTierAdjuster(factors: ["online": 1.24, "south": 1.09]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 46530.2
        )
    }
}
