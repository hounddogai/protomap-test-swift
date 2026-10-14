import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction audit calculation.
    protocol InteractionAuditStep {
        func describe() -> String
        func adjust(_ item: InteractionAudit, value: Double) -> Double
    }

    final class RoundingInteractionAuditAdjuster: InteractionAuditStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredInteractionAuditAdjuster: InteractionAuditStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentInteractionAuditAdjuster: InteractionAuditStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameInteractionAuditAdjuster: InteractionAuditStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: InteractionAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the interaction audit steps in order and keeps a trace of each.
    final class InteractionAuditEngine {
        var steps: [any InteractionAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InteractionAudit) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any InteractionAuditStep = steps[index]
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

        func evaluateAll(_ items: [InteractionAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInteractionAuditEngine() -> InteractionAuditEngine {
        return InteractionAuditEngine(
            steps: [
                RoundingInteractionAuditAdjuster(step: 5.0),
                TieredInteractionAuditAdjuster(
                    bounds: [309.0, 1934.0, 5144.0, 6475.0],
                    rates: [1.07, 1.03, 0.88, 1.12]
                ),
                PercentInteractionAuditAdjuster(percent: 3.1),
                NameInteractionAuditAdjuster(factors: ["online": 0.96, "south": 0.79]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 40888.3
        )
    }
}
