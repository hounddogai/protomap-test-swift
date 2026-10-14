import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure target calculation.
    protocol DisclosureTargetModifier {
        func describe() -> String
        func adjust(_ item: DisclosureTarget, value: Double) -> Double
    }

    final class RoundingDisclosureTargetAdjuster: DisclosureTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDisclosureTargetAdjuster: DisclosureTargetModifier {
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

        func adjust(_ item: DisclosureTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDisclosureTargetAdjuster: DisclosureTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryDisclosureTargetAdjuster: DisclosureTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: DisclosureTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDisclosureTargetAdjuster: DisclosureTargetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the disclosure target steps in order and keeps a trace of each.
    final class DisclosureTargetEngine {
        var steps: [any DisclosureTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DisclosureTarget) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureTargetModifier = steps[index]
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

        func evaluateAll(_ items: [DisclosureTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDisclosureTargetEngine(_ flags: Kit.Flags.Registry) -> DisclosureTargetEngine {
        return DisclosureTargetEngine(
            steps: [
                RoundingDisclosureTargetAdjuster(step: 1.0),
                FlaggedDisclosureTargetAdjuster(flags: flags, flag: "disclosure-target-weighted", percent: 4.3),
                CapDisclosureTargetAdjuster(cap: 30744.0),
                CountryDisclosureTargetAdjuster(factors: ["central": 1.12, "online": 0.82, "north": 0.98]),
                MinimumDisclosureTargetAdjuster(minimum: 30.5),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 61729.0
        )
    }
}
