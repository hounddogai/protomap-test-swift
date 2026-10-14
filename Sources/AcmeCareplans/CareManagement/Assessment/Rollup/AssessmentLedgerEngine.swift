import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment ledger calculation.
    protocol AssessmentLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: AssessmentLedger, value: Double) -> Double
    }

    final class PercentAssessmentLedgerAdjuster: AssessmentLedgerAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitAssessmentLedgerAdjuster: AssessmentLedgerAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: AssessmentLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAssessmentLedgerAdjuster: AssessmentLedgerAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAssessmentLedgerAdjuster: AssessmentLedgerAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the assessment ledger steps in order and keeps a trace of each.
    final class AssessmentLedgerEngine {
        var steps: [any AssessmentLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentLedger) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentLedgerAdjuster = steps[index]
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

        func evaluateAll(_ items: [AssessmentLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentLedgerEngine() -> AssessmentLedgerEngine {
        return AssessmentLedgerEngine(
            steps: [
                PercentAssessmentLedgerAdjuster(percent: 21.1),
                UnitAssessmentLedgerAdjuster(factors: ["west": 1.19, "east": 0.73]),
                MinimumAssessmentLedgerAdjuster(minimum: 32.1),
                RoundingAssessmentLedgerAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 1429.2
        )
    }
}
