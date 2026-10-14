import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback alert override calculation.
    protocol FallbackAlertOverrideFactor {
        func describe() -> String
        func adjust(_ item: FallbackAlertOverride, value: Double) -> Double
    }

    final class CapFallbackAlertOverrideAdjuster: FallbackAlertOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackAlertOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentFallbackAlertOverrideAdjuster: FallbackAlertOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackAlertOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFallbackAlertOverrideAdjuster: FallbackAlertOverrideFactor {
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

        func adjust(_ item: FallbackAlertOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback alert override steps in order and keeps a trace of each.
    final class FallbackAlertOverrideEngine {
        var steps: [any FallbackAlertOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAlertOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackAlertOverride) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackAlertOverrideFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackAlertOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackAlertOverrideEngine(_ flags: Kit.Flags.Registry) -> FallbackAlertOverrideEngine {
        return FallbackAlertOverrideEngine(
            steps: [
                CapFallbackAlertOverrideAdjuster(cap: 24868.0),
                PercentFallbackAlertOverrideAdjuster(percent: 8.3),
                FlaggedFallbackAlertOverrideAdjuster(
                    flags: flags,
                    flag: "fallback-alert-override-fallback",
                    percent: -3.6
                ),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 84260.7
        )
    }
}
