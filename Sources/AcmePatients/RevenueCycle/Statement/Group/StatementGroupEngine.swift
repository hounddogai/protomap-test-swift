import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement group calculation.
    protocol StatementGroupModifier {
        func describe() -> String
        func adjust(_ item: StatementGroup, value: Double) -> Double
    }

    final class TieredStatementGroupAdjuster: StatementGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StatementGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class StatementGroupStartsAtOffsetAdjuster: StatementGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: StatementGroup, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingStatementGroupAdjuster: StatementGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StatementGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStatementGroupAdjuster: StatementGroupModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: StatementGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleStatementGroupAdjuster: StatementGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: StatementGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the statement group steps in order and keeps a trace of each.
    final class StatementGroupEngine {
        var steps: [any StatementGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StatementGroup) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [StatementGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStatementGroupEngine(_ flags: Kit.Flags.Registry) -> StatementGroupEngine {
        return StatementGroupEngine(
            steps: [
                TieredStatementGroupAdjuster(
                    bounds: [6181.0, 6682.0, 7980.0, 9391.0],
                    rates: [0.99, 0.98, 0.91, 1.03]
                ),
                StatementGroupStartsAtOffsetAdjuster(weight: 0.44),
                RoundingStatementGroupAdjuster(step: 0.5),
                FlaggedStatementGroupAdjuster(flags: flags, flag: "statement-group-pending", percent: -7.1),
                TitleStatementGroupAdjuster(factors: ["west": 0.96]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 67187.4
        )
    }
}
