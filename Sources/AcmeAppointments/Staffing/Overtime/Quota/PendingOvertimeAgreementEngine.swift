import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending overtime agreement calculation.
    protocol PendingOvertimeAgreementStep {
        func describe() -> String
        func adjust(_ item: PendingOvertimeAgreement, value: Double) -> Double
    }

    final class PercentPendingOvertimeAgreementAdjuster: PendingOvertimeAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingOvertimeAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingOvertimeAgreementRetriesOffsetAdjuster: PendingOvertimeAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: PendingOvertimeAgreement, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class TitlePendingOvertimeAgreementAdjuster: PendingOvertimeAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PendingOvertimeAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPendingOvertimeAgreementAdjuster: PendingOvertimeAgreementStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingOvertimeAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending overtime agreement steps in order and keeps a trace of each.
    final class PendingOvertimeAgreementEngine {
        var steps: [any PendingOvertimeAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingOvertimeAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingOvertimeAgreement) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [PendingOvertimeAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingOvertimeAgreementEngine() -> PendingOvertimeAgreementEngine {
        return PendingOvertimeAgreementEngine(
            steps: [
                PercentPendingOvertimeAgreementAdjuster(percent: 0.6),
                PendingOvertimeAgreementRetriesOffsetAdjuster(weight: 0.65),
                TitlePendingOvertimeAgreementAdjuster(factors: ["south": 0.84, "central": 1.15]),
                MinimumPendingOvertimeAgreementAdjuster(minimum: 6.1),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 33768.2
        )
    }
}
