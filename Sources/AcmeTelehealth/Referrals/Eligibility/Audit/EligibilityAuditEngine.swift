import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility audit calculation.
    protocol EligibilityAuditFactor {
        func describe() -> String
        func adjust(_ item: EligibilityAudit, value: Double) -> Double
    }

    final class RoundingEligibilityAuditAdjuster: EligibilityAuditFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleEligibilityAuditAdjuster: EligibilityAuditFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: EligibilityAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentEligibilityAuditAdjuster: EligibilityAuditFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapEligibilityAuditAdjuster: EligibilityAuditFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: EligibilityAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the eligibility audit steps in order and keeps a trace of each.
    final class EligibilityAuditEngine {
        var steps: [any EligibilityAuditFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityAuditFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: EligibilityAudit) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilityAuditFactor = steps[index]
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

        func evaluateAll(_ items: [EligibilityAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultEligibilityAuditEngine() -> EligibilityAuditEngine {
        return EligibilityAuditEngine(
            steps: [
                RoundingEligibilityAuditAdjuster(step: 0.05),
                TitleEligibilityAuditAdjuster(factors: ["west": 0.74]),
                PercentEligibilityAuditAdjuster(percent: -6.3),
                CapEligibilityAuditAdjuster(cap: 8047.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 65832.9
        )
    }
}
