import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study adjustment calculation.
    protocol StudyAdjustmentFactor {
        func describe() -> String
        func adjust(_ item: StudyAdjustment, value: Double) -> Double
    }

    final class StudyAdjustmentRateOffsetAdjuster: StudyAdjustmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: StudyAdjustment, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class PercentStudyAdjustmentAdjuster: StudyAdjustmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStudyAdjustmentAdjuster: StudyAdjustmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the study adjustment steps in order and keeps a trace of each.
    final class StudyAdjustmentEngine {
        var steps: [any StudyAdjustmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyAdjustmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StudyAdjustment) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyAdjustmentFactor = steps[index]
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

        func evaluateAll(_ items: [StudyAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStudyAdjustmentEngine() -> StudyAdjustmentEngine {
        return StudyAdjustmentEngine(
            steps: [
                StudyAdjustmentRateOffsetAdjuster(weight: 1.06),
                PercentStudyAdjustmentAdjuster(percent: 18.0),
                RoundingStudyAdjustmentAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 85832.2
        )
    }
}
