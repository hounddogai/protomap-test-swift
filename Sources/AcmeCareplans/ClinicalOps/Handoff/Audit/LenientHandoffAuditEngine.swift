import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the lenient handoff audit calculation.
    protocol LenientHandoffAuditStep {
        func describe() -> String
        func adjust(_ item: LenientHandoffAudit, value: Double) -> Double
    }

    final class MinimumLenientHandoffAuditAdjuster: LenientHandoffAuditStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientHandoffAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLenientHandoffAuditAdjuster: LenientHandoffAuditStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientHandoffAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LenientHandoffAuditLimitOffsetAdjuster: LenientHandoffAuditStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: LenientHandoffAudit, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class PercentLenientHandoffAuditAdjuster: LenientHandoffAuditStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientHandoffAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleLenientHandoffAuditAdjuster: LenientHandoffAuditStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientHandoffAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient handoff audit steps in order and keeps a trace of each.
    final class LenientHandoffAuditEngine {
        var steps: [any LenientHandoffAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientHandoffAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientHandoffAudit) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [LenientHandoffAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientHandoffAuditEngine() -> LenientHandoffAuditEngine {
        return LenientHandoffAuditEngine(
            steps: [
                MinimumLenientHandoffAuditAdjuster(minimum: 40.8),
                RoundingLenientHandoffAuditAdjuster(step: 0.1),
                LenientHandoffAuditLimitOffsetAdjuster(weight: 0.4),
                PercentLenientHandoffAuditAdjuster(percent: -12.8),
                TitleLenientHandoffAuditAdjuster(factors: ["south": 1.27, "east": 0.77, "north": 1.14]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 8977.6
        )
    }
}
