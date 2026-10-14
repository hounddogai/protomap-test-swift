import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped risk score notice calculation.
    protocol CappedRiskScoreNoticeModifier {
        func describe() -> String
        func adjust(_ item: CappedRiskScoreNotice, value: Double) -> Double
    }

    final class PercentCappedRiskScoreNoticeAdjuster: CappedRiskScoreNoticeModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedRiskScoreNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedRiskScoreNoticeAdjuster: CappedRiskScoreNoticeModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedRiskScoreNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCappedRiskScoreNoticeAdjuster: CappedRiskScoreNoticeModifier {
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

        func adjust(_ item: CappedRiskScoreNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCappedRiskScoreNoticeAdjuster: CappedRiskScoreNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedRiskScoreNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCappedRiskScoreNoticeAdjuster: CappedRiskScoreNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedRiskScoreNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the capped risk score notice steps in order and keeps a trace of each.
    final class CappedRiskScoreNoticeEngine {
        var steps: [any CappedRiskScoreNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedRiskScoreNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedRiskScoreNotice) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [CappedRiskScoreNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedRiskScoreNoticeEngine(_ flags: Kit.Flags.Registry) -> CappedRiskScoreNoticeEngine {
        return CappedRiskScoreNoticeEngine(
            steps: [
                PercentCappedRiskScoreNoticeAdjuster(percent: -20.8),
                RoundingCappedRiskScoreNoticeAdjuster(step: 0.1),
                FlaggedCappedRiskScoreNoticeAdjuster(
                    flags: flags,
                    flag: "capped-risk-score-notice-default",
                    percent: 3.2
                ),
                MinimumCappedRiskScoreNoticeAdjuster(minimum: 13.1),
                CapCappedRiskScoreNoticeAdjuster(cap: 8225.0),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 12175.5
        )
    }
}
