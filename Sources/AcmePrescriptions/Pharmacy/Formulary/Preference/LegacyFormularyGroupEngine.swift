import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy formulary group calculation.
    protocol LegacyFormularyGroupAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyFormularyGroup, value: Double) -> Double
    }

    final class RoundingLegacyFormularyGroupAdjuster: LegacyFormularyGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyFormularyGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLegacyFormularyGroupAdjuster: LegacyFormularyGroupAdjuster {
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

        func adjust(_ item: LegacyFormularyGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLegacyFormularyGroupAdjuster: LegacyFormularyGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyFormularyGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLegacyFormularyGroupAdjuster: LegacyFormularyGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyFormularyGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyFormularyGroupPriorityOffsetAdjuster: LegacyFormularyGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: LegacyFormularyGroup, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the legacy formulary group steps in order and keeps a trace of each.
    final class LegacyFormularyGroupEngine {
        var steps: [any LegacyFormularyGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyFormularyGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyFormularyGroup) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [LegacyFormularyGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyFormularyGroupEngine(_ flags: Kit.Flags.Registry) -> LegacyFormularyGroupEngine {
        return LegacyFormularyGroupEngine(
            steps: [
                RoundingLegacyFormularyGroupAdjuster(step: 1.0),
                FlaggedLegacyFormularyGroupAdjuster(
                    flags: flags,
                    flag: "legacy-formulary-group-lenient",
                    percent: 1.0
                ),
                MinimumLegacyFormularyGroupAdjuster(minimum: 14.8),
                CapLegacyFormularyGroupAdjuster(cap: 36055.0),
                LegacyFormularyGroupPriorityOffsetAdjuster(weight: 0.3),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 28742.5
        )
    }
}
