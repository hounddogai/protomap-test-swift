import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment agreement calculation.
    protocol AssessmentAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: AssessmentAgreement, value: Double) -> Double
    }

    final class PercentAssessmentAgreementAdjuster: AssessmentAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAssessmentAgreementAdjuster: AssessmentAgreementAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AssessmentAgreementBatchSizeOffsetAdjuster: AssessmentAgreementAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: AssessmentAgreement, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the assessment agreement steps in order and keeps a trace of each.
    final class AssessmentAgreementEngine {
        var steps: [any AssessmentAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AssessmentAgreement) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [AssessmentAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAssessmentAgreementEngine() -> AssessmentAgreementEngine {
        return AssessmentAgreementEngine(
            steps: [
                PercentAssessmentAgreementAdjuster(percent: 24.8),
                CapAssessmentAgreementAdjuster(cap: 24522.0),
                AssessmentAgreementBatchSizeOffsetAdjuster(weight: 0.11),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 53920.3
        )
    }
}
