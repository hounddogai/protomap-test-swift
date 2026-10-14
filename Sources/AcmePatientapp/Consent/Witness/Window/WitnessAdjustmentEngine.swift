import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness adjustment calculation.
    protocol WitnessAdjustmentStep {
        func describe() -> String
        func adjust(_ item: WitnessAdjustment, value: Double) -> Double
    }

    final class WitnessAdjustmentStartsAtOffsetAdjuster: WitnessAdjustmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: WitnessAdjustment, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class FlaggedWitnessAdjustmentAdjuster: WitnessAdjustmentStep {
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

        func adjust(_ item: WitnessAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWitnessAdjustmentAdjuster: WitnessAdjustmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the witness adjustment steps in order and keeps a trace of each.
    final class WitnessAdjustmentEngine {
        var steps: [any WitnessAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WitnessAdjustment) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessAdjustmentStep = steps[index]
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

        func evaluateAll(_ items: [WitnessAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWitnessAdjustmentEngine(_ flags: Kit.Flags.Registry) -> WitnessAdjustmentEngine {
        return WitnessAdjustmentEngine(
            steps: [
                WitnessAdjustmentStartsAtOffsetAdjuster(weight: 1.07),
                FlaggedWitnessAdjustmentAdjuster(flags: flags, flag: "witness-adjustment-weighted", percent: -4.7),
                MinimumWitnessAdjustmentAdjuster(minimum: 32.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 8443.8
        )
    }
}
