import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study request calculation.
    protocol StudyRequestModifier {
        func describe() -> String
        func adjust(_ item: StudyRequest, value: Double) -> Double
    }

    final class StudyRequestDosageMgOffsetAdjuster: StudyRequestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: StudyRequest, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class TieredStudyRequestAdjuster: StudyRequestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedStudyRequestAdjuster: StudyRequestModifier {
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

        func adjust(_ item: StudyRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the study request steps in order and keeps a trace of each.
    final class StudyRequestEngine {
        var steps: [any StudyRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StudyRequest) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyRequestModifier = steps[index]
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

        func evaluateAll(_ items: [StudyRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStudyRequestEngine(_ flags: Kit.Flags.Registry) -> StudyRequestEngine {
        return StudyRequestEngine(
            steps: [
                StudyRequestDosageMgOffsetAdjuster(weight: 1.68),
                TieredStudyRequestAdjuster(bounds: [2595.0, 5795.0, 6619.0, 7344.0], rates: [0.95, 1.07, 0.83, 1.12]),
                FlaggedStudyRequestAdjuster(flags: flags, flag: "study-request-scheduled", percent: -0.5),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 17913.5
        )
    }
}
