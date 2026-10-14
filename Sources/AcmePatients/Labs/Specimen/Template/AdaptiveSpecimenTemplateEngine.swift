import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive specimen template calculation.
    protocol AdaptiveSpecimenTemplateStep {
        func describe() -> String
        func adjust(_ item: AdaptiveSpecimenTemplate, value: Double) -> Double
    }

    final class FlaggedAdaptiveSpecimenTemplateAdjuster: AdaptiveSpecimenTemplateStep {
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

        func adjust(_ item: AdaptiveSpecimenTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveSpecimenTemplateAdjuster: AdaptiveSpecimenTemplateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveSpecimenTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAdaptiveSpecimenTemplateAdjuster: AdaptiveSpecimenTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveSpecimenTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAdaptiveSpecimenTemplateAdjuster: AdaptiveSpecimenTemplateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveSpecimenTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive specimen template steps in order and keeps a trace of each.
    final class AdaptiveSpecimenTemplateEngine {
        var steps: [any AdaptiveSpecimenTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveSpecimenTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveSpecimenTemplate) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveSpecimenTemplateStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveSpecimenTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveSpecimenTemplateEngine(_ flags: Kit.Flags.Registry) -> AdaptiveSpecimenTemplateEngine {
        return AdaptiveSpecimenTemplateEngine(
            steps: [
                FlaggedAdaptiveSpecimenTemplateAdjuster(
                    flags: flags,
                    flag: "adaptive-specimen-template-weighted",
                    percent: -6.2
                ),
                CapAdaptiveSpecimenTemplateAdjuster(cap: 34584.0),
                RoundingAdaptiveSpecimenTemplateAdjuster(step: 0.05),
                TieredAdaptiveSpecimenTemplateAdjuster(bounds: [3223.0, 8669.0], rates: [1.1, 1.11]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 10722.3
        )
    }
}
