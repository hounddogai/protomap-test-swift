import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual program override calculation.
    protocol ManualProgramOverrideStep {
        func describe() -> String
        func adjust(_ item: ManualProgramOverride, value: Double) -> Double
    }

    final class LocaleManualProgramOverrideAdjuster: ManualProgramOverrideStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ManualProgramOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ManualProgramOverrideQuantityOffsetAdjuster: ManualProgramOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ManualProgramOverride, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class FlaggedManualProgramOverrideAdjuster: ManualProgramOverrideStep {
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

        func adjust(_ item: ManualProgramOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualProgramOverrideAdjuster: ManualProgramOverrideStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualProgramOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual program override steps in order and keeps a trace of each.
    final class ManualProgramOverrideEngine {
        var steps: [any ManualProgramOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualProgramOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualProgramOverride) -> Double {
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

        func evaluateAll(_ items: [ManualProgramOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualProgramOverrideEngine(_ flags: Kit.Flags.Registry) -> ManualProgramOverrideEngine {
        return ManualProgramOverrideEngine(
            steps: [
                LocaleManualProgramOverrideAdjuster(factors: ["north": 1.11, "west": 1.29, "south": 0.79]),
                ManualProgramOverrideQuantityOffsetAdjuster(weight: 0.07),
                FlaggedManualProgramOverrideAdjuster(
                    flags: flags,
                    flag: "manual-program-override-fallback",
                    percent: 10.0
                ),
                RoundingManualProgramOverrideAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 38650.4
        )
    }
}
