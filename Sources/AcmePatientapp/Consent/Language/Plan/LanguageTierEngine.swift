import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language tier calculation.
    protocol LanguageTierStep {
        func describe() -> String
        func adjust(_ item: LanguageTier, value: Double) -> Double
    }

    final class ChannelLanguageTierAdjuster: LanguageTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: LanguageTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentLanguageTierAdjuster: LanguageTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLanguageTierAdjuster: LanguageTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguageTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the language tier steps in order and keeps a trace of each.
    final class LanguageTierEngine {
        var steps: [any LanguageTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LanguageTier) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageTierStep = steps[index]
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

        func evaluateAll(_ items: [LanguageTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLanguageTierEngine() -> LanguageTierEngine {
        return LanguageTierEngine(
            steps: [
                ChannelLanguageTierAdjuster(factors: ["north": 1.28]),
                PercentLanguageTierAdjuster(percent: 15.7),
                RoundingLanguageTierAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 85903.9
        )
    }
}
