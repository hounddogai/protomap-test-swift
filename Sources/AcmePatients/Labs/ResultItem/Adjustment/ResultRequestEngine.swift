import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result request calculation.
    protocol ResultRequestAdjuster {
        func describe() -> String
        func adjust(_ item: ResultRequest, value: Double) -> Double
    }

    final class MinimumResultRequestAdjuster: ResultRequestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ResultRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredResultRequestAdjuster: ResultRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ResultRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleResultRequestAdjuster: ResultRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ResultRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapResultRequestAdjuster: ResultRequestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ResultRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedResultRequestAdjuster: ResultRequestAdjuster {
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

        func adjust(_ item: ResultRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingResultRequestAdjuster: ResultRequestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the result request steps in order and keeps a trace of each.
    final class ResultRequestEngine {
        var steps: [any ResultRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ResultRequest) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [ResultRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultResultRequestEngine(_ flags: Kit.Flags.Registry) -> ResultRequestEngine {
        return ResultRequestEngine(
            steps: [
                MinimumResultRequestAdjuster(minimum: 37.8),
                TieredResultRequestAdjuster(bounds: [4038.0, 5092.0, 6731.0, 9332.0], rates: [1.13, 1.04, 1.14, 0.96]),
                TitleResultRequestAdjuster(factors: ["south": 1.0, "online": 1.22, "east": 0.9]),
                CapResultRequestAdjuster(cap: 30418.0),
                FlaggedResultRequestAdjuster(flags: flags, flag: "result-request-manual", percent: 9.6),
                RoundingResultRequestAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 97272.3
        )
    }
}
