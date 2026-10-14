import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier notice calculation.
    protocol CourierNoticeModifier {
        func describe() -> String
        func adjust(_ item: CourierNotice, value: Double) -> Double
    }

    final class CapCourierNoticeAdjuster: CourierNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCourierNoticeAdjuster: CourierNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CourierNoticeAmountOffsetAdjuster: CourierNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: CourierNotice, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class RoundingCourierNoticeAdjuster: CourierNoticeModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the courier notice steps in order and keeps a trace of each.
    final class CourierNoticeEngine {
        var steps: [any CourierNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CourierNotice) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CourierNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [CourierNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCourierNoticeEngine() -> CourierNoticeEngine {
        return CourierNoticeEngine(
            steps: [
                CapCourierNoticeAdjuster(cap: 10407.0),
                TieredCourierNoticeAdjuster(bounds: [3619.0, 6665.0, 6744.0, 7837.0], rates: [1.05, 0.91, 0.97, 0.81]),
                CourierNoticeAmountOffsetAdjuster(weight: 1.14),
                RoundingCourierNoticeAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 5317.6
        )
    }
}
