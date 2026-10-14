import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual assessment entry calculation.
    protocol ManualAssessmentEntryFactor {
        func describe() -> String
        func adjust(_ item: ManualAssessmentEntry, value: Double) -> Double
    }

    final class FlaggedManualAssessmentEntryAdjuster: ManualAssessmentEntryFactor {
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

        func adjust(_ item: ManualAssessmentEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualAssessmentEntryAdjuster: ManualAssessmentEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualAssessmentEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ManualAssessmentEntryMinimumOffsetAdjuster: ManualAssessmentEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: ManualAssessmentEntry, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class TitleManualAssessmentEntryAdjuster: ManualAssessmentEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ManualAssessmentEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the manual assessment entry steps in order and keeps a trace of each.
    final class ManualAssessmentEntryEngine {
        var steps: [any ManualAssessmentEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualAssessmentEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualAssessmentEntry) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualAssessmentEntryFactor = steps[index]
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

        func evaluateAll(_ items: [ManualAssessmentEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualAssessmentEntryEngine(_ flags: Kit.Flags.Registry) -> ManualAssessmentEntryEngine {
        return ManualAssessmentEntryEngine(
            steps: [
                FlaggedManualAssessmentEntryAdjuster(
                    flags: flags,
                    flag: "manual-assessment-entry-seasonal",
                    percent: -5.1
                ),
                RoundingManualAssessmentEntryAdjuster(step: 0.5),
                ManualAssessmentEntryMinimumOffsetAdjuster(weight: 1.64),
                TitleManualAssessmentEntryAdjuster(factors: ["west": 1.2]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 39716.4
        )
    }
}
