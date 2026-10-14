import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment checkpoint calculation.
    protocol AssessmentCheckpointStep {
        func describe() -> String
        func adjust(_ item: AssessmentCheckpoint, value: Double) -> Double
    }

    final class AssessmentCheckpointCreatedAtOffsetAdjuster: AssessmentCheckpointStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: AssessmentCheckpoint, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class NameAssessmentCheckpointAdjuster: AssessmentCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AssessmentCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAssessmentCheckpointAdjuster: AssessmentCheckpointStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAssessmentCheckpointAdjuster: AssessmentCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the assessment checkpoint steps in order and keeps a trace of each.
    final class AssessmentCheckpointEngine {
        var steps: [any AssessmentCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentCheckpoint) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentCheckpointStep = steps[index]
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

        func evaluateAll(_ items: [AssessmentCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentCheckpointEngine() -> AssessmentCheckpointEngine {
        return AssessmentCheckpointEngine(
            steps: [
                AssessmentCheckpointCreatedAtOffsetAdjuster(weight: 0.12),
                NameAssessmentCheckpointAdjuster(factors: ["east": 0.87, "west": 1.1]),
                TieredAssessmentCheckpointAdjuster(bounds: [4254.0, 6728.0], rates: [0.85, 1.0]),
                PercentAssessmentCheckpointAdjuster(percent: -18.5),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 27998.4
        )
    }
}
