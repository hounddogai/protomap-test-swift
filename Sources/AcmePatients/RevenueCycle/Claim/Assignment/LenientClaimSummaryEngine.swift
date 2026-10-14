import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient claim summary calculation.
    protocol LenientClaimSummaryFactor {
        func describe() -> String
        func adjust(_ item: LenientClaimSummary, value: Double) -> Double
    }

    final class CapLenientClaimSummaryAdjuster: LenientClaimSummaryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientClaimSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLenientClaimSummaryAdjuster: LenientClaimSummaryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientClaimSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientClaimSummaryAdjuster: LenientClaimSummaryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientClaimSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLenientClaimSummaryAdjuster: LenientClaimSummaryFactor {
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

        func adjust(_ item: LenientClaimSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient claim summary steps in order and keeps a trace of each.
    final class LenientClaimSummaryEngine {
        var steps: [any LenientClaimSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientClaimSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientClaimSummary) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [LenientClaimSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientClaimSummaryEngine(_ flags: Kit.Flags.Registry) -> LenientClaimSummaryEngine {
        return LenientClaimSummaryEngine(
            steps: [
                CapLenientClaimSummaryAdjuster(cap: 14707.0),
                PercentLenientClaimSummaryAdjuster(percent: 19.7),
                RoundingLenientClaimSummaryAdjuster(step: 0.05),
                FlaggedLenientClaimSummaryAdjuster(flags: flags, flag: "lenient-claim-summary-global", percent: -2.2),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 23261.0
        )
    }
}
