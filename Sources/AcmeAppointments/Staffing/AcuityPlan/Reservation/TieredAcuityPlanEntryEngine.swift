import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered acuity plan entry calculation.
    protocol TieredAcuityPlanEntryStep {
        func describe() -> String
        func adjust(_ item: TieredAcuityPlanEntry, value: Double) -> Double
    }

    final class PercentTieredAcuityPlanEntryAdjuster: TieredAcuityPlanEntryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredAcuityPlanEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredAcuityPlanEntryAdjuster: TieredAcuityPlanEntryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredAcuityPlanEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTieredAcuityPlanEntryAdjuster: TieredAcuityPlanEntryStep {
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

        func adjust(_ item: TieredAcuityPlanEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredAcuityPlanEntryAdjuster: TieredAcuityPlanEntryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredAcuityPlanEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAcuityPlanEntryMinimumOffsetAdjuster: TieredAcuityPlanEntryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: TieredAcuityPlanEntry, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    /// Runs the tiered acuity plan entry steps in order and keeps a trace of each.
    final class TieredAcuityPlanEntryEngine {
        var steps: [any TieredAcuityPlanEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredAcuityPlanEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredAcuityPlanEntry) -> Double {
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

        func evaluateAll(_ items: [TieredAcuityPlanEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredAcuityPlanEntryEngine(_ flags: Kit.Flags.Registry) -> TieredAcuityPlanEntryEngine {
        return TieredAcuityPlanEntryEngine(
            steps: [
                PercentTieredAcuityPlanEntryAdjuster(percent: -4.1),
                CapTieredAcuityPlanEntryAdjuster(cap: 11313.0),
                FlaggedTieredAcuityPlanEntryAdjuster(
                    flags: flags,
                    flag: "tiered-acuity-plan-entry-global",
                    percent: 4.1
                ),
                RoundingTieredAcuityPlanEntryAdjuster(step: 0.05),
                TieredAcuityPlanEntryMinimumOffsetAdjuster(weight: 0.5),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 70963.0
        )
    }
}
