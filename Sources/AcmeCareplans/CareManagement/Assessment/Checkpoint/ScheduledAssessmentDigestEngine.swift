import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled assessment digest calculation.
    protocol ScheduledAssessmentDigestFactor {
        func describe() -> String
        func adjust(_ item: ScheduledAssessmentDigest, value: Double) -> Double
    }

    final class CapScheduledAssessmentDigestAdjuster: ScheduledAssessmentDigestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledAssessmentDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceScheduledAssessmentDigestAdjuster: ScheduledAssessmentDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ScheduledAssessmentDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumScheduledAssessmentDigestAdjuster: ScheduledAssessmentDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledAssessmentDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the scheduled assessment digest steps in order and keeps a trace of each.
    final class ScheduledAssessmentDigestEngine {
        var steps: [any ScheduledAssessmentDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAssessmentDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledAssessmentDigest) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledAssessmentDigestFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledAssessmentDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledAssessmentDigestEngine() -> ScheduledAssessmentDigestEngine {
        return ScheduledAssessmentDigestEngine(
            steps: [
                CapScheduledAssessmentDigestAdjuster(cap: 22429.0),
                SourceScheduledAssessmentDigestAdjuster(factors: ["central": 0.88, "west": 1.3]),
                MinimumScheduledAssessmentDigestAdjuster(minimum: 49.4),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 85326.0
        )
    }
}
