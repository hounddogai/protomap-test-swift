import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional revocation score calculation.
    protocol RegionalRevocationScoreAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalRevocationScore, value: Double) -> Double
    }

    final class RoundingRegionalRevocationScoreAdjuster: RegionalRevocationScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalRevocationScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRegionalRevocationScoreAdjuster: RegionalRevocationScoreAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalRevocationScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRegionalRevocationScoreAdjuster: RegionalRevocationScoreAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalRevocationScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRegionalRevocationScoreAdjuster: RegionalRevocationScoreAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalRevocationScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionalRevocationScoreAmountOffsetAdjuster: RegionalRevocationScoreAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: RegionalRevocationScore, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class MinimumRegionalRevocationScoreAdjuster: RegionalRevocationScoreAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalRevocationScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional revocation score steps in order and keeps a trace of each.
    final class RegionalRevocationScoreEngine {
        var steps: [any RegionalRevocationScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalRevocationScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalRevocationScore) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [RegionalRevocationScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalRevocationScoreEngine() -> RegionalRevocationScoreEngine {
        return RegionalRevocationScoreEngine(
            steps: [
                RoundingRegionalRevocationScoreAdjuster(step: 5.0),
                CapRegionalRevocationScoreAdjuster(cap: 43921.0),
                TieredRegionalRevocationScoreAdjuster(
                    bounds: [984.0, 5875.0, 7273.0, 7494.0],
                    rates: [0.86, 1.16, 0.9, 0.97]
                ),
                PercentRegionalRevocationScoreAdjuster(percent: -12.0),
                RegionalRevocationScoreAmountOffsetAdjuster(weight: 1.1),
                MinimumRegionalRevocationScoreAdjuster(minimum: 20.9),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 47215.1
        )
    }
}
