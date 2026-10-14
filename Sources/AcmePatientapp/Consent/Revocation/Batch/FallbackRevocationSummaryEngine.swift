import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback revocation summary calculation.
    protocol FallbackRevocationSummaryModifier {
        func describe() -> String
        func adjust(_ item: FallbackRevocationSummary, value: Double) -> Double
    }

    final class RoundingFallbackRevocationSummaryAdjuster: FallbackRevocationSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackRevocationSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedFallbackRevocationSummaryAdjuster: FallbackRevocationSummaryModifier {
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

        func adjust(_ item: FallbackRevocationSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackRevocationSummaryAdjuster: FallbackRevocationSummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackRevocationSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback revocation summary steps in order and keeps a trace of each.
    final class FallbackRevocationSummaryEngine {
        var steps: [any FallbackRevocationSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackRevocationSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackRevocationSummary) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackRevocationSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackRevocationSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackRevocationSummaryEngine(_ flags: Kit.Flags.Registry) -> FallbackRevocationSummaryEngine {
        return FallbackRevocationSummaryEngine(
            steps: [
                RoundingFallbackRevocationSummaryAdjuster(step: 0.05),
                FlaggedFallbackRevocationSummaryAdjuster(
                    flags: flags,
                    flag: "fallback-revocation-summary-legacy",
                    percent: -2.2
                ),
                CapFallbackRevocationSummaryAdjuster(cap: 31428.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 51501.0
        )
    }
}
