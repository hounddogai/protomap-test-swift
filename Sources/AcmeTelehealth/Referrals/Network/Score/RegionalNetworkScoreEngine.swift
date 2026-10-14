import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional network score calculation.
    protocol RegionalNetworkScoreFactor {
        func describe() -> String
        func adjust(_ item: RegionalNetworkScore, value: Double) -> Double
    }

    final class CapRegionalNetworkScoreAdjuster: RegionalNetworkScoreFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalNetworkScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRegionalNetworkScoreAdjuster: RegionalNetworkScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalNetworkScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRegionalNetworkScoreAdjuster: RegionalNetworkScoreFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalNetworkScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionalNetworkScoreRateOffsetAdjuster: RegionalNetworkScoreFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: RegionalNetworkScore, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the regional network score steps in order and keeps a trace of each.
    final class RegionalNetworkScoreEngine {
        var steps: [any RegionalNetworkScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalNetworkScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalNetworkScore) -> Double {
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

        func evaluateAll(_ items: [RegionalNetworkScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalNetworkScoreEngine() -> RegionalNetworkScoreEngine {
        return RegionalNetworkScoreEngine(
            steps: [
                CapRegionalNetworkScoreAdjuster(cap: 44676.0),
                RoundingRegionalNetworkScoreAdjuster(step: 1.0),
                TieredRegionalNetworkScoreAdjuster(bounds: [4398.0, 5580.0, 9837.0], rates: [1.08, 0.95, 0.8]),
                RegionalNetworkScoreRateOffsetAdjuster(weight: 1.61),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 16248.0
        )
    }
}
