import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial target calculation.
    protocol DenialTargetAdjuster {
        func describe() -> String
        func adjust(_ item: DenialTarget, value: Double) -> Double
    }

    final class FlaggedDenialTargetAdjuster: DenialTargetAdjuster {
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

        func adjust(_ item: DenialTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDenialTargetAdjuster: DenialTargetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleDenialTargetAdjuster: DenialTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DenialTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDenialTargetAdjuster: DenialTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the denial target steps in order and keeps a trace of each.
    final class DenialTargetEngine {
        var steps: [any DenialTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DenialTarget) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialTargetAdjuster = steps[index]
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

        func evaluateAll(_ items: [DenialTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDenialTargetEngine(_ flags: Kit.Flags.Registry) -> DenialTargetEngine {
        return DenialTargetEngine(
            steps: [
                FlaggedDenialTargetAdjuster(flags: flags, flag: "denial-target-fallback", percent: -1.6),
                CapDenialTargetAdjuster(cap: 13731.0),
                TitleDenialTargetAdjuster(factors: ["retail": 1.2, "south": 1.4]),
                PercentDenialTargetAdjuster(percent: 5.6),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 55026.9
        )
    }
}
