import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global risk score audit calculation.
    protocol GlobalRiskScoreAuditStep {
        func describe() -> String
        func adjust(_ item: GlobalRiskScoreAudit, value: Double) -> Double
    }

    final class GlobalRiskScoreAuditVisitMinutesOffsetAdjuster: GlobalRiskScoreAuditStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: GlobalRiskScoreAudit, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class MinimumGlobalRiskScoreAuditAdjuster: GlobalRiskScoreAuditStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalRiskScoreAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapGlobalRiskScoreAuditAdjuster: GlobalRiskScoreAuditStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalRiskScoreAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredGlobalRiskScoreAuditAdjuster: GlobalRiskScoreAuditStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalRiskScoreAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingGlobalRiskScoreAuditAdjuster: GlobalRiskScoreAuditStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalRiskScoreAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global risk score audit steps in order and keeps a trace of each.
    final class GlobalRiskScoreAuditEngine {
        var steps: [any GlobalRiskScoreAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalRiskScoreAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalRiskScoreAudit) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalRiskScoreAuditStep = steps[index]
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

        func evaluateAll(_ items: [GlobalRiskScoreAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalRiskScoreAuditEngine() -> GlobalRiskScoreAuditEngine {
        return GlobalRiskScoreAuditEngine(
            steps: [
                GlobalRiskScoreAuditVisitMinutesOffsetAdjuster(weight: 0.51),
                MinimumGlobalRiskScoreAuditAdjuster(minimum: 45.4),
                CapGlobalRiskScoreAuditAdjuster(cap: 27014.0),
                TieredGlobalRiskScoreAuditAdjuster(bounds: [3548.0, 6060.0], rates: [0.85, 0.99]),
                RoundingGlobalRiskScoreAuditAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 29644.2
        )
    }
}
