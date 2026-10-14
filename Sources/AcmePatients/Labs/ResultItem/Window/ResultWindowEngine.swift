import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result window calculation.
    protocol ResultWindowAdjuster {
        func describe() -> String
        func adjust(_ item: ResultWindow, value: Double) -> Double
    }

    final class ResultWindowScoreOffsetAdjuster: ResultWindowAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ResultWindow, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class RoundingResultWindowAdjuster: ResultWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedResultWindowAdjuster: ResultWindowAdjuster {
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

        func adjust(_ item: ResultWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredResultWindowAdjuster: ResultWindowAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ResultWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the result window steps in order and keeps a trace of each.
    final class ResultWindowEngine {
        var steps: [any ResultWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ResultWindow) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [ResultWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultResultWindowEngine(_ flags: Kit.Flags.Registry) -> ResultWindowEngine {
        return ResultWindowEngine(
            steps: [
                ResultWindowScoreOffsetAdjuster(weight: 0.75),
                RoundingResultWindowAdjuster(step: 0.1),
                FlaggedResultWindowAdjuster(flags: flags, flag: "result-window-seasonal", percent: 0.7),
                TieredResultWindowAdjuster(bounds: [2558.0, 8870.0], rates: [1.03, 1.18]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 76601.5
        )
    }
}
