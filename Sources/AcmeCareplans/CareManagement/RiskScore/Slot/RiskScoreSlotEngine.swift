import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score slot calculation.
    protocol RiskScoreSlotAdjuster {
        func describe() -> String
        func adjust(_ item: RiskScoreSlot, value: Double) -> Double
    }

    final class RoundingRiskScoreSlotAdjuster: RiskScoreSlotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRiskScoreSlotAdjuster: RiskScoreSlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitRiskScoreSlotAdjuster: RiskScoreSlotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: RiskScoreSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRiskScoreSlotAdjuster: RiskScoreSlotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRiskScoreSlotAdjuster: RiskScoreSlotAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: RiskScoreSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the risk score slot steps in order and keeps a trace of each.
    final class RiskScoreSlotEngine {
        var steps: [any RiskScoreSlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreSlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RiskScoreSlot) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [RiskScoreSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRiskScoreSlotEngine(_ flags: Kit.Flags.Registry) -> RiskScoreSlotEngine {
        return RiskScoreSlotEngine(
            steps: [
                RoundingRiskScoreSlotAdjuster(step: 0.25),
                TieredRiskScoreSlotAdjuster(bounds: [1809.0, 4448.0, 7410.0], rates: [0.92, 0.99, 1.19]),
                UnitRiskScoreSlotAdjuster(factors: ["east": 1.25, "retail": 0.77]),
                MinimumRiskScoreSlotAdjuster(minimum: 25.8),
                FlaggedRiskScoreSlotAdjuster(flags: flags, flag: "risk-score-slot-batched", percent: 4.6),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 50495.1
        )
    }
}
