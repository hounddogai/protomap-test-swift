import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure notice calculation.
    protocol ClosureNoticeFactor {
        func describe() -> String
        func adjust(_ item: ClosureNotice, value: Double) -> Double
    }

    final class ClosureNoticeRefillsOffsetAdjuster: ClosureNoticeFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: ClosureNotice, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapClosureNoticeAdjuster: ClosureNoticeFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingClosureNoticeAdjuster: ClosureNoticeFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentClosureNoticeAdjuster: ClosureNoticeFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardClosureNoticeAdjuster: ClosureNoticeFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: ClosureNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the closure notice steps in order and keeps a trace of each.
    final class ClosureNoticeEngine {
        var steps: [any ClosureNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClosureNotice) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureNoticeFactor = steps[index]
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

        func evaluateAll(_ items: [ClosureNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClosureNoticeEngine() -> ClosureNoticeEngine {
        return ClosureNoticeEngine(
            steps: [
                ClosureNoticeRefillsOffsetAdjuster(weight: 0.31),
                CapClosureNoticeAdjuster(cap: 15744.0),
                RoundingClosureNoticeAdjuster(step: 0.05),
                PercentClosureNoticeAdjuster(percent: 5.2),
                WardClosureNoticeAdjuster(factors: ["north": 1.11, "online": 0.79]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 79252.0
        )
    }
}
