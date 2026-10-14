import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result profile calculation.
    protocol ResultProfileModifier {
        func describe() -> String
        func adjust(_ item: ResultProfile, value: Double) -> Double
    }

    final class MinimumResultProfileAdjuster: ResultProfileModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ResultProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentResultProfileAdjuster: ResultProfileModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ResultProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapResultProfileAdjuster: ResultProfileModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ResultProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelResultProfileAdjuster: ResultProfileModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ResultProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredResultProfileAdjuster: ResultProfileModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ResultProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingResultProfileAdjuster: ResultProfileModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the result profile steps in order and keeps a trace of each.
    final class ResultProfileEngine {
        var steps: [any ResultProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ResultProfile) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ResultProfileModifier = steps[index]
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

        func evaluateAll(_ items: [ResultProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultResultProfileEngine() -> ResultProfileEngine {
        return ResultProfileEngine(
            steps: [
                MinimumResultProfileAdjuster(minimum: 1.7),
                PercentResultProfileAdjuster(percent: 0.6),
                CapResultProfileAdjuster(cap: 24085.0),
                ChannelResultProfileAdjuster(factors: ["online": 1.24]),
                TieredResultProfileAdjuster(bounds: [3529.0, 7458.0], rates: [0.96, 0.8]),
                RoundingResultProfileAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 31674.2
        )
    }
}
