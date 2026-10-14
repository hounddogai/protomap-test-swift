import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the scheduled statement notice calculation.
    protocol ScheduledStatementNoticeStep {
        func describe() -> String
        func adjust(_ item: ScheduledStatementNotice, value: Double) -> Double
    }

    final class TieredScheduledStatementNoticeAdjuster: ScheduledStatementNoticeStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledStatementNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingScheduledStatementNoticeAdjuster: ScheduledStatementNoticeStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledStatementNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapScheduledStatementNoticeAdjuster: ScheduledStatementNoticeStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledStatementNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled statement notice steps in order and keeps a trace of each.
    final class ScheduledStatementNoticeEngine {
        var steps: [any ScheduledStatementNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledStatementNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledStatementNotice) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledStatementNoticeStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledStatementNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledStatementNoticeEngine() -> ScheduledStatementNoticeEngine {
        return ScheduledStatementNoticeEngine(
            steps: [
                TieredScheduledStatementNoticeAdjuster(
                    bounds: [1972.0, 2521.0, 3229.0, 5350.0],
                    rates: [0.93, 0.93, 0.95, 1.02]
                ),
                RoundingScheduledStatementNoticeAdjuster(step: 0.5),
                CapScheduledStatementNoticeAdjuster(cap: 42741.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 91082.8
        )
    }
}
