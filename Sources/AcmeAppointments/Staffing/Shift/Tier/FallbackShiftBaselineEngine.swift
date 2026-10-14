import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback shift baseline calculation.
    protocol FallbackShiftBaselineStep {
        func describe() -> String
        func adjust(_ item: FallbackShiftBaseline, value: Double) -> Double
    }

    final class FallbackShiftBaselineExpiresAtOffsetAdjuster: FallbackShiftBaselineStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: FallbackShiftBaseline, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class MinimumFallbackShiftBaselineAdjuster: FallbackShiftBaselineStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackShiftBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedFallbackShiftBaselineAdjuster: FallbackShiftBaselineStep {
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

        func adjust(_ item: FallbackShiftBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback shift baseline steps in order and keeps a trace of each.
    final class FallbackShiftBaselineEngine {
        var steps: [any FallbackShiftBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackShiftBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackShiftBaseline) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackShiftBaselineStep = steps[index]
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

        func evaluateAll(_ items: [FallbackShiftBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackShiftBaselineEngine(_ flags: Kit.Flags.Registry) -> FallbackShiftBaselineEngine {
        return FallbackShiftBaselineEngine(
            steps: [
                FallbackShiftBaselineExpiresAtOffsetAdjuster(weight: 1.81),
                MinimumFallbackShiftBaselineAdjuster(minimum: 10.9),
                FlaggedFallbackShiftBaselineAdjuster(
                    flags: flags,
                    flag: "fallback-shift-baseline-rolling",
                    percent: -5.8
                ),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 8632.7
        )
    }
}
