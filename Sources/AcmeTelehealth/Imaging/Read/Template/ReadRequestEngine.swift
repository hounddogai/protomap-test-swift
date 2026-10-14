import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read request calculation.
    protocol ReadRequestModifier {
        func describe() -> String
        func adjust(_ item: ReadRequest, value: Double) -> Double
    }

    final class NameReadRequestAdjuster: ReadRequestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ReadRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingReadRequestAdjuster: ReadRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumReadRequestAdjuster: ReadRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReadRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedReadRequestAdjuster: ReadRequestModifier {
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

        func adjust(_ item: ReadRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapReadRequestAdjuster: ReadRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredReadRequestAdjuster: ReadRequestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the read request steps in order and keeps a trace of each.
    final class ReadRequestEngine {
        var steps: [any ReadRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReadRequest) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadRequestModifier = steps[index]
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

        func evaluateAll(_ items: [ReadRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReadRequestEngine(_ flags: Kit.Flags.Registry) -> ReadRequestEngine {
        return ReadRequestEngine(
            steps: [
                NameReadRequestAdjuster(factors: ["central": 0.91, "west": 1.28]),
                RoundingReadRequestAdjuster(step: 0.05),
                MinimumReadRequestAdjuster(minimum: 22.9),
                FlaggedReadRequestAdjuster(flags: flags, flag: "read-request-weighted", percent: -6.7),
                CapReadRequestAdjuster(cap: 28088.0),
                TieredReadRequestAdjuster(bounds: [955.0, 5227.0, 7974.0], rates: [1.12, 1.17, 0.82]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 61507.7
        )
    }
}
