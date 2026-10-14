import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient dispense override calculation.
    protocol LenientDispenseOverrideStep {
        func describe() -> String
        func adjust(_ item: LenientDispenseOverride, value: Double) -> Double
    }

    final class LenientDispenseOverrideDurationMinutesOffsetAdjuster: LenientDispenseOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: LenientDispenseOverride, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class TieredLenientDispenseOverrideAdjuster: LenientDispenseOverrideStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientDispenseOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLenientDispenseOverrideAdjuster: LenientDispenseOverrideStep {
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

        func adjust(_ item: LenientDispenseOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient dispense override steps in order and keeps a trace of each.
    final class LenientDispenseOverrideEngine {
        var steps: [any LenientDispenseOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientDispenseOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientDispenseOverride) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientDispenseOverrideStep = steps[index]
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

        func evaluateAll(_ items: [LenientDispenseOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientDispenseOverrideEngine(_ flags: Kit.Flags.Registry) -> LenientDispenseOverrideEngine {
        return LenientDispenseOverrideEngine(
            steps: [
                LenientDispenseOverrideDurationMinutesOffsetAdjuster(weight: 1.52),
                TieredLenientDispenseOverrideAdjuster(bounds: [4098.0, 6939.0], rates: [1.07, 1.18]),
                FlaggedLenientDispenseOverrideAdjuster(
                    flags: flags,
                    flag: "lenient-dispense-override-strict",
                    percent: 9.8
                ),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 23737.0
        )
    }
}
