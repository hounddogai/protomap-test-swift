import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness window calculation.
    protocol WitnessWindowModifier {
        func describe() -> String
        func adjust(_ item: WitnessWindow, value: Double) -> Double
    }

    final class WitnessWindowBudgetOffsetAdjuster: WitnessWindowModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: WitnessWindow, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class PercentWitnessWindowAdjuster: WitnessWindowModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedWitnessWindowAdjuster: WitnessWindowModifier {
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

        func adjust(_ item: WitnessWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the witness window steps in order and keeps a trace of each.
    final class WitnessWindowEngine {
        var steps: [any WitnessWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WitnessWindow) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessWindowModifier = steps[index]
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

        func evaluateAll(_ items: [WitnessWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWitnessWindowEngine(_ flags: Kit.Flags.Registry) -> WitnessWindowEngine {
        return WitnessWindowEngine(
            steps: [
                WitnessWindowBudgetOffsetAdjuster(weight: 1.42),
                PercentWitnessWindowAdjuster(percent: -18.3),
                FlaggedWitnessWindowAdjuster(flags: flags, flag: "witness-window-global", percent: 4.1),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 25437.3
        )
    }
}
