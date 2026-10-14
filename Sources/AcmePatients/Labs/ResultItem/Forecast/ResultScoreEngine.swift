import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result score calculation.
    protocol ResultScoreStep {
        func describe() -> String
        func adjust(_ item: ResultScore, value: Double) -> Double
    }

    final class CapResultScoreAdjuster: ResultScoreStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ResultScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentResultScoreAdjuster: ResultScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ResultScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedResultScoreAdjuster: ResultScoreStep {
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

        func adjust(_ item: ResultScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ResultScoreRevisionOffsetAdjuster: ResultScoreStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: ResultScore, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class TieredResultScoreAdjuster: ResultScoreStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ResultScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameResultScoreAdjuster: ResultScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ResultScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the result score steps in order and keeps a trace of each.
    final class ResultScoreEngine {
        var steps: [any ResultScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ResultScore) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ResultScoreStep = steps[index]
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

        func evaluateAll(_ items: [ResultScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultResultScoreEngine(_ flags: Kit.Flags.Registry) -> ResultScoreEngine {
        return ResultScoreEngine(
            steps: [
                CapResultScoreAdjuster(cap: 1673.0),
                PercentResultScoreAdjuster(percent: -23.8),
                FlaggedResultScoreAdjuster(flags: flags, flag: "result-score-global", percent: 3.3),
                ResultScoreRevisionOffsetAdjuster(weight: 0.87),
                TieredResultScoreAdjuster(bounds: [138.0, 445.0, 3670.0, 8850.0], rates: [1.05, 0.9, 1.15, 0.9]),
                NameResultScoreAdjuster(factors: ["north": 0.93, "online": 1.03]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 53614.8
        )
    }
}
