import AcmePlatform
import Foundation

extension Consent {
    /// One step of the legacy disclosure baseline calculation.
    protocol LegacyDisclosureBaselineStep {
        func describe() -> String
        func adjust(_ item: LegacyDisclosureBaseline, value: Double) -> Double
    }

    final class RoundingLegacyDisclosureBaselineAdjuster: LegacyDisclosureBaselineStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyDisclosureBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLegacyDisclosureBaselineAdjuster: LegacyDisclosureBaselineStep {
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

        func adjust(_ item: LegacyDisclosureBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyDisclosureBaselineAdjuster: LegacyDisclosureBaselineStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyDisclosureBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy disclosure baseline steps in order and keeps a trace of each.
    final class LegacyDisclosureBaselineEngine {
        var steps: [any LegacyDisclosureBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyDisclosureBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyDisclosureBaseline) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyDisclosureBaselineStep = steps[index]
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

        func evaluateAll(_ items: [LegacyDisclosureBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyDisclosureBaselineEngine(_ flags: Kit.Flags.Registry) -> LegacyDisclosureBaselineEngine {
        return LegacyDisclosureBaselineEngine(
            steps: [
                RoundingLegacyDisclosureBaselineAdjuster(step: 0.5),
                FlaggedLegacyDisclosureBaselineAdjuster(
                    flags: flags,
                    flag: "legacy-disclosure-baseline-pending",
                    percent: -3.5
                ),
                TieredLegacyDisclosureBaselineAdjuster(bounds: [2289.0, 9106.0], rates: [0.99, 1.17]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 7074.4
        )
    }
}
