import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score notice calculation.
    protocol RiskScoreNoticeFactor {
        func describe() -> String
        func adjust(_ item: RiskScoreNotice, value: Double) -> Double
    }

    final class SourceRiskScoreNoticeAdjuster: RiskScoreNoticeFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: RiskScoreNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRiskScoreNoticeAdjuster: RiskScoreNoticeFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RiskScoreNoticePriorityOffsetAdjuster: RiskScoreNoticeFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: RiskScoreNotice, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class CapRiskScoreNoticeAdjuster: RiskScoreNoticeFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRiskScoreNoticeAdjuster: RiskScoreNoticeFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRiskScoreNoticeAdjuster: RiskScoreNoticeFactor {
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

        func adjust(_ item: RiskScoreNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the risk score notice steps in order and keeps a trace of each.
    final class RiskScoreNoticeEngine {
        var steps: [any RiskScoreNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RiskScoreNotice) -> Double {
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

        func evaluateAll(_ items: [RiskScoreNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRiskScoreNoticeEngine(_ flags: Kit.Flags.Registry) -> RiskScoreNoticeEngine {
        return RiskScoreNoticeEngine(
            steps: [
                SourceRiskScoreNoticeAdjuster(factors: ["east": 1.24]),
                MinimumRiskScoreNoticeAdjuster(minimum: 40.1),
                RiskScoreNoticePriorityOffsetAdjuster(weight: 1.34),
                CapRiskScoreNoticeAdjuster(cap: 678.0),
                TieredRiskScoreNoticeAdjuster(bounds: [2861.0, 6442.0], rates: [1.14, 0.84]),
                FlaggedRiskScoreNoticeAdjuster(flags: flags, flag: "risk-score-notice-tiered", percent: -8.2),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 50230.0
        )
    }
}
