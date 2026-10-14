import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score audit calculation.
    protocol RiskScoreAuditStep {
        func describe() -> String
        func adjust(_ item: RiskScoreAudit, value: Double) -> Double
    }

    final class RiskScoreAuditWindowDaysOffsetAdjuster: RiskScoreAuditStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: RiskScoreAudit, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class PercentRiskScoreAuditAdjuster: RiskScoreAuditStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RiskScoreAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRiskScoreAuditAdjuster: RiskScoreAuditStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRiskScoreAuditAdjuster: RiskScoreAuditStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the risk score audit steps in order and keeps a trace of each.
    final class RiskScoreAuditEngine {
        var steps: [any RiskScoreAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RiskScoreAudit) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [RiskScoreAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRiskScoreAuditEngine() -> RiskScoreAuditEngine {
        return RiskScoreAuditEngine(
            steps: [
                RiskScoreAuditWindowDaysOffsetAdjuster(weight: 0.44),
                PercentRiskScoreAuditAdjuster(percent: -4.1),
                RoundingRiskScoreAuditAdjuster(step: 0.1),
                TieredRiskScoreAuditAdjuster(bounds: [5128.0, 5188.0, 8404.0], rates: [1.14, 0.92, 1.1]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 86620.5
        )
    }
}
