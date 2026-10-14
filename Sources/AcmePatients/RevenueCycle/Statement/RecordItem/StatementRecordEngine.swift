import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement record calculation.
    protocol StatementRecordModifier {
        func describe() -> String
        func adjust(_ item: StatementRecord, value: Double) -> Double
    }

    final class MinimumStatementRecordAdjuster: StatementRecordModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class StatementRecordCostOffsetAdjuster: StatementRecordModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: StatementRecord, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class SegmentStatementRecordAdjuster: StatementRecordModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: StatementRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentStatementRecordAdjuster: StatementRecordModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the statement record steps in order and keeps a trace of each.
    final class StatementRecordEngine {
        var steps: [any StatementRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StatementRecord) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementRecordModifier = steps[index]
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

        func evaluateAll(_ items: [StatementRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStatementRecordEngine() -> StatementRecordEngine {
        return StatementRecordEngine(
            steps: [
                MinimumStatementRecordAdjuster(minimum: 4.5),
                StatementRecordCostOffsetAdjuster(weight: 0.17),
                SegmentStatementRecordAdjuster(factors: ["online": 0.97, "retail": 1.19]),
                PercentStatementRecordAdjuster(percent: 15.4),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 13506.1
        )
    }
}
