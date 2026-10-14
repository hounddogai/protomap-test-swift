import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen summary calculation.
    protocol SpecimenSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: SpecimenSummary, value: Double) -> Double
    }

    final class FlaggedSpecimenSummaryAdjuster: SpecimenSummaryAdjuster {
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

        func adjust(_ item: SpecimenSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSpecimenSummaryAdjuster: SpecimenSummaryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSpecimenSummaryAdjuster: SpecimenSummaryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SpecimenSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSpecimenSummaryAdjuster: SpecimenSummaryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SpecimenSummaryCapacityOffsetAdjuster: SpecimenSummaryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: SpecimenSummary, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class RoundingSpecimenSummaryAdjuster: SpecimenSummaryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the specimen summary steps in order and keeps a trace of each.
    final class SpecimenSummaryEngine {
        var steps: [any SpecimenSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SpecimenSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenSummaryAdjuster = steps[index]
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

        func evaluateAll(_ items: [SpecimenSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSpecimenSummaryEngine(_ flags: Kit.Flags.Registry) -> SpecimenSummaryEngine {
        return SpecimenSummaryEngine(
            steps: [
                FlaggedSpecimenSummaryAdjuster(flags: flags, flag: "specimen-summary-capped", percent: -3.1),
                MinimumSpecimenSummaryAdjuster(minimum: 45.1),
                PercentSpecimenSummaryAdjuster(percent: 24.1),
                CapSpecimenSummaryAdjuster(cap: 3212.0),
                SpecimenSummaryCapacityOffsetAdjuster(weight: 1.69),
                RoundingSpecimenSummaryAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 19685.1
        )
    }
}
