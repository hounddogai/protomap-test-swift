import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary discharge plan summary calculation.
    protocol PrimaryDischargePlanSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryDischargePlanSummary, value: Double) -> Double
    }

    final class FlaggedPrimaryDischargePlanSummaryAdjuster: PrimaryDischargePlanSummaryAdjuster {
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

        func adjust(_ item: PrimaryDischargePlanSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryDischargePlanSummaryAdjuster: PrimaryDischargePlanSummaryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryDischargePlanSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class UnitPrimaryDischargePlanSummaryAdjuster: PrimaryDischargePlanSummaryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PrimaryDischargePlanSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPrimaryDischargePlanSummaryAdjuster: PrimaryDischargePlanSummaryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryDischargePlanSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPrimaryDischargePlanSummaryAdjuster: PrimaryDischargePlanSummaryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryDischargePlanSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary discharge plan summary steps in order and keeps a trace of each.
    final class PrimaryDischargePlanSummaryEngine {
        var steps: [any PrimaryDischargePlanSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryDischargePlanSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryDischargePlanSummary) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [PrimaryDischargePlanSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryDischargePlanSummaryEngine(_ flags: Kit.Flags.Registry) -> PrimaryDischargePlanSummaryEngine {
        return PrimaryDischargePlanSummaryEngine(
            steps: [
                FlaggedPrimaryDischargePlanSummaryAdjuster(
                    flags: flags,
                    flag: "primary-discharge-plan-summary-fallback",
                    percent: -5.6
                ),
                CapPrimaryDischargePlanSummaryAdjuster(cap: 23809.0),
                UnitPrimaryDischargePlanSummaryAdjuster(factors: ["central": 0.89, "east": 0.88, "north": 1.09]),
                RoundingPrimaryDischargePlanSummaryAdjuster(step: 0.25),
                MinimumPrimaryDischargePlanSummaryAdjuster(minimum: 43.3),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 17272.9
        )
    }
}
