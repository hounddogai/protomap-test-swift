import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the legacy follow up checkpoint calculation.
    protocol LegacyFollowUpCheckpointStep {
        func describe() -> String
        func adjust(_ item: LegacyFollowUpCheckpoint, value: Double) -> Double
    }

    final class PercentLegacyFollowUpCheckpointAdjuster: LegacyFollowUpCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyFollowUpCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyFollowUpCheckpointAdjuster: LegacyFollowUpCheckpointStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyFollowUpCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLegacyFollowUpCheckpointAdjuster: LegacyFollowUpCheckpointStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyFollowUpCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ChannelLegacyFollowUpCheckpointAdjuster: LegacyFollowUpCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: LegacyFollowUpCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LegacyFollowUpCheckpointVisitMinutesOffsetAdjuster: LegacyFollowUpCheckpointStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: LegacyFollowUpCheckpoint, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class RoundingLegacyFollowUpCheckpointAdjuster: LegacyFollowUpCheckpointStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyFollowUpCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy follow up checkpoint steps in order and keeps a trace of each.
    final class LegacyFollowUpCheckpointEngine {
        var steps: [any LegacyFollowUpCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyFollowUpCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyFollowUpCheckpoint) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [LegacyFollowUpCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyFollowUpCheckpointEngine() -> LegacyFollowUpCheckpointEngine {
        return LegacyFollowUpCheckpointEngine(
            steps: [
                PercentLegacyFollowUpCheckpointAdjuster(percent: -18.5),
                CapLegacyFollowUpCheckpointAdjuster(cap: 32431.0),
                TieredLegacyFollowUpCheckpointAdjuster(bounds: [2873.0, 8018.0], rates: [1.09, 1.14]),
                ChannelLegacyFollowUpCheckpointAdjuster(factors: ["east": 1.19]),
                LegacyFollowUpCheckpointVisitMinutesOffsetAdjuster(weight: 1.87),
                RoundingLegacyFollowUpCheckpointAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 72138.8
        )
    }
}
