import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default statement ledger calculation.
    protocol DefaultStatementLedgerStep {
        func describe() -> String
        func adjust(_ item: DefaultStatementLedger, value: Double) -> Double
    }

    final class MinimumDefaultStatementLedgerAdjuster: DefaultStatementLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultStatementLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleDefaultStatementLedgerAdjuster: DefaultStatementLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DefaultStatementLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DefaultStatementLedgerStartsAtOffsetAdjuster: DefaultStatementLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: DefaultStatementLedger, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class PercentDefaultStatementLedgerAdjuster: DefaultStatementLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultStatementLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default statement ledger steps in order and keeps a trace of each.
    final class DefaultStatementLedgerEngine {
        var steps: [any DefaultStatementLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultStatementLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultStatementLedger) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultStatementLedgerStep = steps[index]
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

        func evaluateAll(_ items: [DefaultStatementLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultStatementLedgerEngine() -> DefaultStatementLedgerEngine {
        return DefaultStatementLedgerEngine(
            steps: [
                MinimumDefaultStatementLedgerAdjuster(minimum: 35.6),
                TitleDefaultStatementLedgerAdjuster(factors: ["online": 0.72, "central": 0.87, "west": 1.09]),
                DefaultStatementLedgerStartsAtOffsetAdjuster(weight: 1.39),
                PercentDefaultStatementLedgerAdjuster(percent: 23.8),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 69828.7
        )
    }
}
