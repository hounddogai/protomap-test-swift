import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen target calculation.
    protocol SpecimenTargetStep {
        func describe() -> String
        func adjust(_ item: SpecimenTarget, value: Double) -> Double
    }

    final class SpecimenTargetBudgetOffsetAdjuster: SpecimenTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: SpecimenTarget, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class FlaggedSpecimenTargetAdjuster: SpecimenTargetStep {
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

        func adjust(_ item: SpecimenTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSpecimenTargetAdjuster: SpecimenTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the specimen target steps in order and keeps a trace of each.
    final class SpecimenTargetEngine {
        var steps: [any SpecimenTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SpecimenTarget) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenTargetStep = steps[index]
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

        func evaluateAll(_ items: [SpecimenTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSpecimenTargetEngine(_ flags: Kit.Flags.Registry) -> SpecimenTargetEngine {
        return SpecimenTargetEngine(
            steps: [
                SpecimenTargetBudgetOffsetAdjuster(weight: 1.5),
                FlaggedSpecimenTargetAdjuster(flags: flags, flag: "specimen-target-capped", percent: 4.9),
                MinimumSpecimenTargetAdjuster(minimum: 16.4),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 9116.4
        )
    }
}
