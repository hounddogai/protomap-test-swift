import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary threshold calculation.
    protocol FormularyThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: FormularyThreshold, value: Double) -> Double
    }

    final class CapFormularyThresholdAdjuster: FormularyThresholdAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FormularyThresholdLimitOffsetAdjuster: FormularyThresholdAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: FormularyThreshold, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class FlaggedFormularyThresholdAdjuster: FormularyThresholdAdjuster {
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

        func adjust(_ item: FormularyThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFormularyThresholdAdjuster: FormularyThresholdAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFormularyThresholdAdjuster: FormularyThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FormularyThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the formulary threshold steps in order and keeps a trace of each.
    final class FormularyThresholdEngine {
        var steps: [any FormularyThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FormularyThreshold) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [FormularyThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFormularyThresholdEngine(_ flags: Kit.Flags.Registry) -> FormularyThresholdEngine {
        return FormularyThresholdEngine(
            steps: [
                CapFormularyThresholdAdjuster(cap: 27650.0),
                FormularyThresholdLimitOffsetAdjuster(weight: 1.49),
                FlaggedFormularyThresholdAdjuster(flags: flags, flag: "formulary-threshold-pending", percent: 7.3),
                PercentFormularyThresholdAdjuster(percent: -5.7),
                RoundingFormularyThresholdAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 75071.5
        )
    }
}
