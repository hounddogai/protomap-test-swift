import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive risk score checkpoint calculation.
    protocol AdaptiveRiskScoreCheckpointModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveRiskScoreCheckpoint, value: Double) -> Double
    }

    final class PercentAdaptiveRiskScoreCheckpointAdjuster: AdaptiveRiskScoreCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveRiskScoreCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveRiskScoreCheckpointAdjuster: AdaptiveRiskScoreCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveRiskScoreCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AdaptiveRiskScoreCheckpointCopayOffsetAdjuster: AdaptiveRiskScoreCheckpointModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: AdaptiveRiskScoreCheckpoint, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class MinimumAdaptiveRiskScoreCheckpointAdjuster: AdaptiveRiskScoreCheckpointModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveRiskScoreCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive risk score checkpoint steps in order and keeps a trace of each.
    final class AdaptiveRiskScoreCheckpointEngine {
        var steps: [any AdaptiveRiskScoreCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRiskScoreCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveRiskScoreCheckpoint) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [AdaptiveRiskScoreCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRiskScoreCheckpointEngine() -> AdaptiveRiskScoreCheckpointEngine {
        return AdaptiveRiskScoreCheckpointEngine(
            steps: [
                PercentAdaptiveRiskScoreCheckpointAdjuster(percent: 12.3),
                TieredAdaptiveRiskScoreCheckpointAdjuster(bounds: [3099.0, 6285.0], rates: [0.87, 1.06]),
                AdaptiveRiskScoreCheckpointCopayOffsetAdjuster(weight: 1.94),
                MinimumAdaptiveRiskScoreCheckpointAdjuster(minimum: 14.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 56829.4
        )
    }
}
