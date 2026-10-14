import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary interaction template calculation.
    protocol PrimaryInteractionTemplateModifier {
        func describe() -> String
        func adjust(_ item: PrimaryInteractionTemplate, value: Double) -> Double
    }

    final class MinimumPrimaryInteractionTemplateAdjuster: PrimaryInteractionTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryInteractionTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPrimaryInteractionTemplateAdjuster: PrimaryInteractionTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryInteractionTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPrimaryInteractionTemplateAdjuster: PrimaryInteractionTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryInteractionTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPrimaryInteractionTemplateAdjuster: PrimaryInteractionTemplateModifier {
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

        func adjust(_ item: PrimaryInteractionTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryPrimaryInteractionTemplateAdjuster: PrimaryInteractionTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: PrimaryInteractionTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary interaction template steps in order and keeps a trace of each.
    final class PrimaryInteractionTemplateEngine {
        var steps: [any PrimaryInteractionTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryInteractionTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryInteractionTemplate) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryInteractionTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryInteractionTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryInteractionTemplateEngine(_ flags: Kit.Flags.Registry) -> PrimaryInteractionTemplateEngine {
        return PrimaryInteractionTemplateEngine(
            steps: [
                MinimumPrimaryInteractionTemplateAdjuster(minimum: 25.3),
                RoundingPrimaryInteractionTemplateAdjuster(step: 5.0),
                CapPrimaryInteractionTemplateAdjuster(cap: 45311.0),
                FlaggedPrimaryInteractionTemplateAdjuster(
                    flags: flags,
                    flag: "primary-interaction-template-tiered",
                    percent: -3.3
                ),
                CountryPrimaryInteractionTemplateAdjuster(factors: ["retail": 1.11, "east": 1.13, "online": 1.0]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 26220.8
        )
    }
}
