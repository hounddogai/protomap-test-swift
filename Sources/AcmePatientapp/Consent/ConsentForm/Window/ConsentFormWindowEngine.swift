import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form window calculation.
    protocol ConsentFormWindowAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormWindow, value: Double) -> Double
    }

    final class CapConsentFormWindowAdjuster: ConsentFormWindowAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingConsentFormWindowAdjuster: ConsentFormWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelConsentFormWindowAdjuster: ConsentFormWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ConsentFormWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedConsentFormWindowAdjuster: ConsentFormWindowAdjuster {
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

        func adjust(_ item: ConsentFormWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumConsentFormWindowAdjuster: ConsentFormWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the consent form window steps in order and keeps a trace of each.
    final class ConsentFormWindowEngine {
        var steps: [any ConsentFormWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ConsentFormWindow) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormWindowAdjuster = steps[index]
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

        func evaluateAll(_ items: [ConsentFormWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultConsentFormWindowEngine(_ flags: Kit.Flags.Registry) -> ConsentFormWindowEngine {
        return ConsentFormWindowEngine(
            steps: [
                CapConsentFormWindowAdjuster(cap: 49519.0),
                RoundingConsentFormWindowAdjuster(step: 5.0),
                LabelConsentFormWindowAdjuster(factors: ["east": 1.19]),
                FlaggedConsentFormWindowAdjuster(flags: flags, flag: "consent-form-window-primary", percent: -1.5),
                MinimumConsentFormWindowAdjuster(minimum: 12.2),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 6408.5
        )
    }
}
