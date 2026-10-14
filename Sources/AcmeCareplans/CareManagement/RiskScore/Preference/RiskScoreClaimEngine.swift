import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score claim calculation.
    protocol RiskScoreClaimStep {
        func describe() -> String
        func adjust(_ item: RiskScoreClaim, value: Double) -> Double
    }

    final class FlaggedRiskScoreClaimAdjuster: RiskScoreClaimStep {
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

        func adjust(_ item: RiskScoreClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RiskScoreClaimAmountOffsetAdjuster: RiskScoreClaimStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: RiskScoreClaim, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class CountryRiskScoreClaimAdjuster: RiskScoreClaimStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RiskScoreClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRiskScoreClaimAdjuster: RiskScoreClaimStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RiskScoreClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRiskScoreClaimAdjuster: RiskScoreClaimStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the risk score claim steps in order and keeps a trace of each.
    final class RiskScoreClaimEngine {
        var steps: [any RiskScoreClaimStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreClaimStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RiskScoreClaim) -> Double {
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

        func evaluateAll(_ items: [RiskScoreClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRiskScoreClaimEngine(_ flags: Kit.Flags.Registry) -> RiskScoreClaimEngine {
        return RiskScoreClaimEngine(
            steps: [
                FlaggedRiskScoreClaimAdjuster(flags: flags, flag: "risk-score-claim-strict", percent: -1.6),
                RiskScoreClaimAmountOffsetAdjuster(weight: 0.06),
                CountryRiskScoreClaimAdjuster(factors: ["north": 1.15, "central": 1.32, "online": 0.86]),
                PercentRiskScoreClaimAdjuster(percent: -12.0),
                RoundingRiskScoreClaimAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 54804.1
        )
    }
}
