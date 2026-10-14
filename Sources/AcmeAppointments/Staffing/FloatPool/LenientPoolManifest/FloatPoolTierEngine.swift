import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool tier calculation.
    protocol FloatPoolTierStep {
        func describe() -> String
        func adjust(_ item: FloatPoolTier, value: Double) -> Double
    }

    final class PercentFloatPoolTierAdjuster: FloatPoolTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFloatPoolTierAdjuster: FloatPoolTierStep {
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

        func adjust(_ item: FloatPoolTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFloatPoolTierAdjuster: FloatPoolTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the float pool tier steps in order and keeps a trace of each.
    final class FloatPoolTierEngine {
        var steps: [any FloatPoolTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FloatPoolTier) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolTierStep = steps[index]
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

        func evaluateAll(_ items: [FloatPoolTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFloatPoolTierEngine(_ flags: Kit.Flags.Registry) -> FloatPoolTierEngine {
        return FloatPoolTierEngine(
            steps: [
                PercentFloatPoolTierAdjuster(percent: -17.2),
                FlaggedFloatPoolTierAdjuster(flags: flags, flag: "float-pool-tier-regional", percent: -8.9),
                CapFloatPoolTierAdjuster(cap: 1840.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 14216.9
        )
    }
}
