import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score summary calculation.
    protocol RiskScoreSummaryModifier {
        func describe() -> String
        func adjust(_ item: RiskScoreSummary, value: Double) -> Double
    }

    final class RoundingRiskScoreSummaryAdjuster: RiskScoreSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRiskScoreSummaryAdjuster: RiskScoreSummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RiskScoreSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRiskScoreSummaryAdjuster: RiskScoreSummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRiskScoreSummaryAdjuster: RiskScoreSummaryModifier {
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

        func adjust(_ item: RiskScoreSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRiskScoreSummaryAdjuster: RiskScoreSummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RiskScoreSummaryGraceDaysOffsetAdjuster: RiskScoreSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: RiskScoreSummary, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    /// Runs the risk score summary steps in order and keeps a trace of each.
    final class RiskScoreSummaryEngine {
        var steps: [any RiskScoreSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RiskScoreSummary) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [RiskScoreSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRiskScoreSummaryEngine(_ flags: Kit.Flags.Registry) -> RiskScoreSummaryEngine {
        return RiskScoreSummaryEngine(
            steps: [
                RoundingRiskScoreSummaryAdjuster(step: 0.5),
                PercentRiskScoreSummaryAdjuster(percent: -9.0),
                CapRiskScoreSummaryAdjuster(cap: 11071.0),
                FlaggedRiskScoreSummaryAdjuster(flags: flags, flag: "risk-score-summary-batched", percent: -8.4),
                TieredRiskScoreSummaryAdjuster(bounds: [1619.0, 2876.0, 7410.0], rates: [0.96, 1.18, 0.92]),
                RiskScoreSummaryGraceDaysOffsetAdjuster(weight: 0.54),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 23593.5
        )
    }
}
