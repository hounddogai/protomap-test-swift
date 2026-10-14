import AcmePlatform
import Foundation

extension Consent {
    /// One step of the default disclosure window calculation.
    protocol DefaultDisclosureWindowAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultDisclosureWindow, value: Double) -> Double
    }

    final class CategoryDefaultDisclosureWindowAdjuster: DefaultDisclosureWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: DefaultDisclosureWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDefaultDisclosureWindowAdjuster: DefaultDisclosureWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultDisclosureWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumDefaultDisclosureWindowAdjuster: DefaultDisclosureWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultDisclosureWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultDisclosureWindowAdjuster: DefaultDisclosureWindowAdjuster {
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

        func adjust(_ item: DefaultDisclosureWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDefaultDisclosureWindowAdjuster: DefaultDisclosureWindowAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultDisclosureWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default disclosure window steps in order and keeps a trace of each.
    final class DefaultDisclosureWindowEngine {
        var steps: [any DefaultDisclosureWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultDisclosureWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultDisclosureWindow) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultDisclosureWindowAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultDisclosureWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultDisclosureWindowEngine(_ flags: Kit.Flags.Registry) -> DefaultDisclosureWindowEngine {
        return DefaultDisclosureWindowEngine(
            steps: [
                CategoryDefaultDisclosureWindowAdjuster(factors: ["west": 0.71, "north": 0.83, "central": 1.33]),
                RoundingDefaultDisclosureWindowAdjuster(step: 1.0),
                MinimumDefaultDisclosureWindowAdjuster(minimum: 38.2),
                FlaggedDefaultDisclosureWindowAdjuster(
                    flags: flags,
                    flag: "default-disclosure-window-seasonal",
                    percent: 7.0
                ),
                CapDefaultDisclosureWindowAdjuster(cap: 36448.0),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 85723.4
        )
    }
}
