import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered risk score claim calculation.
    protocol TieredRiskScoreClaimFactor {
        func describe() -> String
        func adjust(_ item: TieredRiskScoreClaim, value: Double) -> Double
    }

    final class MinimumTieredRiskScoreClaimAdjuster: TieredRiskScoreClaimFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredRiskScoreClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTieredRiskScoreClaimAdjuster: TieredRiskScoreClaimFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredRiskScoreClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRiskScoreClaimMinimumOffsetAdjuster: TieredRiskScoreClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: TieredRiskScoreClaim, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class ChannelTieredRiskScoreClaimAdjuster: TieredRiskScoreClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: TieredRiskScoreClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingTieredRiskScoreClaimAdjuster: TieredRiskScoreClaimFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredRiskScoreClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapTieredRiskScoreClaimAdjuster: TieredRiskScoreClaimFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredRiskScoreClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered risk score claim steps in order and keeps a trace of each.
    final class TieredRiskScoreClaimEngine {
        var steps: [any TieredRiskScoreClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRiskScoreClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredRiskScoreClaim) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [TieredRiskScoreClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredRiskScoreClaimEngine() -> TieredRiskScoreClaimEngine {
        return TieredRiskScoreClaimEngine(
            steps: [
                MinimumTieredRiskScoreClaimAdjuster(minimum: 37.4),
                PercentTieredRiskScoreClaimAdjuster(percent: 8.4),
                TieredRiskScoreClaimMinimumOffsetAdjuster(weight: 1.18),
                ChannelTieredRiskScoreClaimAdjuster(factors: ["north": 0.94, "online": 1.28]),
                RoundingTieredRiskScoreClaimAdjuster(step: 0.1),
                CapTieredRiskScoreClaimAdjuster(cap: 32061.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 16309.0
        )
    }
}
