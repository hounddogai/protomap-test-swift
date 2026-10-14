import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending specimen cycle calculation.
    protocol PendingSpecimenCycleModifier {
        func describe() -> String
        func adjust(_ item: PendingSpecimenCycle, value: Double) -> Double
    }

    final class CountryPendingSpecimenCycleAdjuster: PendingSpecimenCycleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: PendingSpecimenCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPendingSpecimenCycleAdjuster: PendingSpecimenCycleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingSpecimenCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPendingSpecimenCycleAdjuster: PendingSpecimenCycleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingSpecimenCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPendingSpecimenCycleAdjuster: PendingSpecimenCycleModifier {
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

        func adjust(_ item: PendingSpecimenCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending specimen cycle steps in order and keeps a trace of each.
    final class PendingSpecimenCycleEngine {
        var steps: [any PendingSpecimenCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingSpecimenCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingSpecimenCycle) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingSpecimenCycleModifier = steps[index]
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

        func evaluateAll(_ items: [PendingSpecimenCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingSpecimenCycleEngine(_ flags: Kit.Flags.Registry) -> PendingSpecimenCycleEngine {
        return PendingSpecimenCycleEngine(
            steps: [
                CountryPendingSpecimenCycleAdjuster(factors: ["north": 0.71]),
                CapPendingSpecimenCycleAdjuster(cap: 40924.0),
                RoundingPendingSpecimenCycleAdjuster(step: 0.1),
                FlaggedPendingSpecimenCycleAdjuster(flags: flags, flag: "pending-specimen-cycle-global", percent: 8.2),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 85065.0
        )
    }
}
