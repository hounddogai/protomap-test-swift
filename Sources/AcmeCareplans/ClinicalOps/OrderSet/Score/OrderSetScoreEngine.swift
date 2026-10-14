import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set score calculation.
    protocol OrderSetScoreModifier {
        func describe() -> String
        func adjust(_ item: OrderSetScore, value: Double) -> Double
    }

    final class FlaggedOrderSetScoreAdjuster: OrderSetScoreModifier {
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

        func adjust(_ item: OrderSetScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingOrderSetScoreAdjuster: OrderSetScoreModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentOrderSetScoreAdjuster: OrderSetScoreModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapOrderSetScoreAdjuster: OrderSetScoreModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the order set score steps in order and keeps a trace of each.
    final class OrderSetScoreEngine {
        var steps: [any OrderSetScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OrderSetScore) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetScoreModifier = steps[index]
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

        func evaluateAll(_ items: [OrderSetScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOrderSetScoreEngine(_ flags: Kit.Flags.Registry) -> OrderSetScoreEngine {
        return OrderSetScoreEngine(
            steps: [
                FlaggedOrderSetScoreAdjuster(flags: flags, flag: "order-set-score-pending", percent: -0.6),
                RoundingOrderSetScoreAdjuster(step: 5.0),
                PercentOrderSetScoreAdjuster(percent: -8.0),
                CapOrderSetScoreAdjuster(cap: 44952.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 55810.3
        )
    }
}
