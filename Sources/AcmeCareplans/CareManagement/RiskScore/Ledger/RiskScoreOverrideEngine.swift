import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score override calculation.
    protocol RiskScoreOverrideFactor {
        func describe() -> String
        func adjust(_ item: RiskScoreOverride, value: Double) -> Double
    }

    final class FlaggedRiskScoreOverrideAdjuster: RiskScoreOverrideFactor {
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

        func adjust(_ item: RiskScoreOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRiskScoreOverrideAdjuster: RiskScoreOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RiskScoreOverrideRefillsOffsetAdjuster: RiskScoreOverrideFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: RiskScoreOverride, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapRiskScoreOverrideAdjuster: RiskScoreOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the risk score override steps in order and keeps a trace of each.
    final class RiskScoreOverrideEngine {
        var steps: [any RiskScoreOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RiskScoreOverride) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreOverrideFactor = steps[index]
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

        func evaluateAll(_ items: [RiskScoreOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRiskScoreOverrideEngine(_ flags: Kit.Flags.Registry) -> RiskScoreOverrideEngine {
        return RiskScoreOverrideEngine(
            steps: [
                FlaggedRiskScoreOverrideAdjuster(flags: flags, flag: "risk-score-override-regional", percent: 6.5),
                MinimumRiskScoreOverrideAdjuster(minimum: 33.6),
                RiskScoreOverrideRefillsOffsetAdjuster(weight: 0.58),
                CapRiskScoreOverrideAdjuster(cap: 38048.0),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 53901.3
        )
    }
}
