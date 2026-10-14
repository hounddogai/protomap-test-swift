import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default risk score group calculation.
    protocol DefaultRiskScoreGroupAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultRiskScoreGroup, value: Double) -> Double
    }

    final class FlaggedDefaultRiskScoreGroupAdjuster: DefaultRiskScoreGroupAdjuster {
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

        func adjust(_ item: DefaultRiskScoreGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultRiskScoreGroupAdjuster: DefaultRiskScoreGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultRiskScoreGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DefaultRiskScoreGroupRatioOffsetAdjuster: DefaultRiskScoreGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: DefaultRiskScoreGroup, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class CapDefaultRiskScoreGroupAdjuster: DefaultRiskScoreGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultRiskScoreGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDefaultRiskScoreGroupAdjuster: DefaultRiskScoreGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultRiskScoreGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the default risk score group steps in order and keeps a trace of each.
    final class DefaultRiskScoreGroupEngine {
        var steps: [any DefaultRiskScoreGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRiskScoreGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultRiskScoreGroup) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultRiskScoreGroupAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultRiskScoreGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultRiskScoreGroupEngine(_ flags: Kit.Flags.Registry) -> DefaultRiskScoreGroupEngine {
        return DefaultRiskScoreGroupEngine(
            steps: [
                FlaggedDefaultRiskScoreGroupAdjuster(
                    flags: flags,
                    flag: "default-risk-score-group-primary",
                    percent: 5.0
                ),
                RoundingDefaultRiskScoreGroupAdjuster(step: 0.25),
                DefaultRiskScoreGroupRatioOffsetAdjuster(weight: 0.77),
                CapDefaultRiskScoreGroupAdjuster(cap: 13620.0),
                MinimumDefaultRiskScoreGroupAdjuster(minimum: 33.4),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 62768.6
        )
    }
}
