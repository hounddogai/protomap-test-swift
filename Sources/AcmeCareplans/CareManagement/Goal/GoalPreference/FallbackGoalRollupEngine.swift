import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback goal rollup calculation.
    protocol FallbackGoalRollupFactor {
        func describe() -> String
        func adjust(_ item: FallbackGoalRollup, value: Double) -> Double
    }

    final class MinimumFallbackGoalRollupAdjuster: FallbackGoalRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackGoalRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFallbackGoalRollupAdjuster: FallbackGoalRollupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackGoalRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelFallbackGoalRollupAdjuster: FallbackGoalRollupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: FallbackGoalRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback goal rollup steps in order and keeps a trace of each.
    final class FallbackGoalRollupEngine {
        var steps: [any FallbackGoalRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackGoalRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackGoalRollup) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [FallbackGoalRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackGoalRollupEngine() -> FallbackGoalRollupEngine {
        return FallbackGoalRollupEngine(
            steps: [
                MinimumFallbackGoalRollupAdjuster(minimum: 29.8),
                PercentFallbackGoalRollupAdjuster(percent: 2.6),
                ChannelFallbackGoalRollupAdjuster(factors: ["west": 1.02, "south": 1.38, "online": 1.08]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 54363.5
        )
    }
}
