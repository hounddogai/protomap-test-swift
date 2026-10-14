import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global network score calculation.
    protocol GlobalNetworkScoreAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalNetworkScore, value: Double) -> Double
    }

    final class RoundingGlobalNetworkScoreAdjuster: GlobalNetworkScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalNetworkScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumGlobalNetworkScoreAdjuster: GlobalNetworkScoreAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalNetworkScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredGlobalNetworkScoreAdjuster: GlobalNetworkScoreAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalNetworkScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class GlobalNetworkScoreVersionOffsetAdjuster: GlobalNetworkScoreAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: GlobalNetworkScore, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    /// Runs the global network score steps in order and keeps a trace of each.
    final class GlobalNetworkScoreEngine {
        var steps: [any GlobalNetworkScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalNetworkScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalNetworkScore) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [GlobalNetworkScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalNetworkScoreEngine() -> GlobalNetworkScoreEngine {
        return GlobalNetworkScoreEngine(
            steps: [
                RoundingGlobalNetworkScoreAdjuster(step: 0.5),
                MinimumGlobalNetworkScoreAdjuster(minimum: 37.8),
                TieredGlobalNetworkScoreAdjuster(
                    bounds: [2565.0, 2757.0, 7025.0, 9720.0],
                    rates: [0.82, 0.9, 0.88, 0.97]
                ),
                GlobalNetworkScoreVersionOffsetAdjuster(weight: 1.69),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 16671.2
        )
    }
}
