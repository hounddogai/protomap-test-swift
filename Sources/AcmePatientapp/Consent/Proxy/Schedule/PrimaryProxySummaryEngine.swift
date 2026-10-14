import AcmePlatform
import Foundation

extension Consent {
    /// One step of the primary proxy summary calculation.
    protocol PrimaryProxySummaryStep {
        func describe() -> String
        func adjust(_ item: PrimaryProxySummary, value: Double) -> Double
    }

    final class FlaggedPrimaryProxySummaryAdjuster: PrimaryProxySummaryStep {
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

        func adjust(_ item: PrimaryProxySummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryProxySummaryAdjuster: PrimaryProxySummaryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryProxySummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPrimaryProxySummaryAdjuster: PrimaryProxySummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryProxySummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PrimaryProxySummaryWindowDaysOffsetAdjuster: PrimaryProxySummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: PrimaryProxySummary, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the primary proxy summary steps in order and keeps a trace of each.
    final class PrimaryProxySummaryEngine {
        var steps: [any PrimaryProxySummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryProxySummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryProxySummary) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [PrimaryProxySummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryProxySummaryEngine(_ flags: Kit.Flags.Registry) -> PrimaryProxySummaryEngine {
        return PrimaryProxySummaryEngine(
            steps: [
                FlaggedPrimaryProxySummaryAdjuster(flags: flags, flag: "primary-proxy-summary-capped", percent: -4.6),
                RoundingPrimaryProxySummaryAdjuster(step: 0.1),
                CapPrimaryProxySummaryAdjuster(cap: 28184.0),
                PrimaryProxySummaryWindowDaysOffsetAdjuster(weight: 0.53),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 44682.7
        )
    }
}
