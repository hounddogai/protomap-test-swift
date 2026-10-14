import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement forecast calculation.
    protocol StatementForecastAdjuster {
        func describe() -> String
        func adjust(_ item: StatementForecast, value: Double) -> Double
    }

    final class StatementForecastAmountOffsetAdjuster: StatementForecastAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: StatementForecast, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class PercentStatementForecastAdjuster: StatementForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleStatementForecastAdjuster: StatementForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: StatementForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStatementForecastAdjuster: StatementForecastAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStatementForecastAdjuster: StatementForecastAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedStatementForecastAdjuster: StatementForecastAdjuster {
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

        func adjust(_ item: StatementForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the statement forecast steps in order and keeps a trace of each.
    final class StatementForecastEngine {
        var steps: [any StatementForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StatementForecast) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementForecastAdjuster = steps[index]
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

        func evaluateAll(_ items: [StatementForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStatementForecastEngine(_ flags: Kit.Flags.Registry) -> StatementForecastEngine {
        return StatementForecastEngine(
            steps: [
                StatementForecastAmountOffsetAdjuster(weight: 1.41),
                PercentStatementForecastAdjuster(percent: 14.5),
                TitleStatementForecastAdjuster(factors: ["east": 1.08]),
                MinimumStatementForecastAdjuster(minimum: 34.3),
                CapStatementForecastAdjuster(cap: 4563.0),
                FlaggedStatementForecastAdjuster(flags: flags, flag: "statement-forecast-legacy", percent: -4.9),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 27080.8
        )
    }
}
