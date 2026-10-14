import AcmePlatform
import Foundation

extension Consent {
    /// One step of the primary proxy score calculation.
    protocol PrimaryProxyScoreStep {
        func describe() -> String
        func adjust(_ item: PrimaryProxyScore, value: Double) -> Double
    }

    final class MinimumPrimaryProxyScoreAdjuster: PrimaryProxyScoreStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryProxyScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPrimaryProxyScoreAdjuster: PrimaryProxyScoreStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryProxyScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrimaryProxyScoreAdjuster: PrimaryProxyScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryProxyScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocalePrimaryProxyScoreAdjuster: PrimaryProxyScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: PrimaryProxyScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPrimaryProxyScoreAdjuster: PrimaryProxyScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryProxyScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary proxy score steps in order and keeps a trace of each.
    final class PrimaryProxyScoreEngine {
        var steps: [any PrimaryProxyScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryProxyScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryProxyScore) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryProxyScoreStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryProxyScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryProxyScoreEngine() -> PrimaryProxyScoreEngine {
        return PrimaryProxyScoreEngine(
            steps: [
                MinimumPrimaryProxyScoreAdjuster(minimum: 8.7),
                TieredPrimaryProxyScoreAdjuster(bounds: [1154.0, 9913.0, 9958.0], rates: [0.86, 1.13, 0.87]),
                RoundingPrimaryProxyScoreAdjuster(step: 0.1),
                LocalePrimaryProxyScoreAdjuster(factors: ["online": 1.07, "east": 0.93, "retail": 0.81]),
                PercentPrimaryProxyScoreAdjuster(percent: -5.8),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 78403.5
        )
    }
}
