import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge audit calculation.
    protocol ChargeAuditFactor {
        func describe() -> String
        func adjust(_ item: ChargeAudit, value: Double) -> Double
    }

    final class TitleChargeAuditAdjuster: ChargeAuditFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ChargeAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapChargeAuditAdjuster: ChargeAuditFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingChargeAuditAdjuster: ChargeAuditFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumChargeAuditAdjuster: ChargeAuditFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentChargeAuditAdjuster: ChargeAuditFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge audit steps in order and keeps a trace of each.
    final class ChargeAuditEngine {
        var steps: [any ChargeAuditFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeAuditFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ChargeAudit) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [ChargeAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultChargeAuditEngine() -> ChargeAuditEngine {
        return ChargeAuditEngine(
            steps: [
                TitleChargeAuditAdjuster(factors: ["retail": 1.28, "north": 1.34]),
                CapChargeAuditAdjuster(cap: 21360.0),
                RoundingChargeAuditAdjuster(step: 0.5),
                MinimumChargeAuditAdjuster(minimum: 42.8),
                PercentChargeAuditAdjuster(percent: 22.7),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 90065.4
        )
    }
}
