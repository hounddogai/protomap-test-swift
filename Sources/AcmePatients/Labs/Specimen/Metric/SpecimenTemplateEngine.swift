import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen template calculation.
    protocol SpecimenTemplateStep {
        func describe() -> String
        func adjust(_ item: SpecimenTemplate, value: Double) -> Double
    }

    final class CapSpecimenTemplateAdjuster: SpecimenTemplateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSpecimenTemplateAdjuster: SpecimenTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSpecimenTemplateAdjuster: SpecimenTemplateStep {
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

        func adjust(_ item: SpecimenTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the specimen template steps in order and keeps a trace of each.
    final class SpecimenTemplateEngine {
        var steps: [any SpecimenTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SpecimenTemplate) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenTemplateStep = steps[index]
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

        func evaluateAll(_ items: [SpecimenTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSpecimenTemplateEngine(_ flags: Kit.Flags.Registry) -> SpecimenTemplateEngine {
        return SpecimenTemplateEngine(
            steps: [
                CapSpecimenTemplateAdjuster(cap: 6249.0),
                RoundingSpecimenTemplateAdjuster(step: 5.0),
                FlaggedSpecimenTemplateAdjuster(flags: flags, flag: "specimen-template-rolling", percent: -0.8),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 85260.2
        )
    }
}
