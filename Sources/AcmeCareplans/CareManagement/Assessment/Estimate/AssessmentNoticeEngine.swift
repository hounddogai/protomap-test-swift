import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment notice calculation.
    protocol AssessmentNoticeStep {
        func describe() -> String
        func adjust(_ item: AssessmentNotice, value: Double) -> Double
    }

    final class PercentAssessmentNoticeAdjuster: AssessmentNoticeStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAssessmentNoticeAdjuster: AssessmentNoticeStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameAssessmentNoticeAdjuster: AssessmentNoticeStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AssessmentNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the assessment notice steps in order and keeps a trace of each.
    final class AssessmentNoticeEngine {
        var steps: [any AssessmentNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AssessmentNotice) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentNoticeStep = steps[index]
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

        func evaluateAll(_ items: [AssessmentNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAssessmentNoticeEngine() -> AssessmentNoticeEngine {
        return AssessmentNoticeEngine(
            steps: [
                PercentAssessmentNoticeAdjuster(percent: 13.7),
                TieredAssessmentNoticeAdjuster(bounds: [4696.0, 6306.0, 9701.0], rates: [0.97, 1.09, 1.04]),
                NameAssessmentNoticeAdjuster(factors: ["east": 0.84, "north": 1.07, "retail": 1.17]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 10212.5
        )
    }
}
