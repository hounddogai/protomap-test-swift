import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement slot calculation.
    protocol StatementSlotModifier {
        func describe() -> String
        func adjust(_ item: StatementSlot, value: Double) -> Double
    }

    final class TieredStatementSlotAdjuster: StatementSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StatementSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStatementSlotAdjuster: StatementSlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentStatementSlotAdjuster: StatementSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelStatementSlotAdjuster: StatementSlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StatementSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStatementSlotAdjuster: StatementSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the statement slot steps in order and keeps a trace of each.
    final class StatementSlotEngine {
        var steps: [any StatementSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StatementSlot) -> Double {
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

        func evaluateAll(_ items: [StatementSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStatementSlotEngine() -> StatementSlotEngine {
        return StatementSlotEngine(
            steps: [
                TieredStatementSlotAdjuster(bounds: [1610.0, 8504.0], rates: [1.0, 0.97]),
                MinimumStatementSlotAdjuster(minimum: 49.9),
                PercentStatementSlotAdjuster(percent: 16.5),
                LabelStatementSlotAdjuster(factors: ["north": 1.05, "east": 0.85]),
                CapStatementSlotAdjuster(cap: 40380.0),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 35458.5
        )
    }
}
