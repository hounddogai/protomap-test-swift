import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set schedule calculation.
    protocol OrderSetScheduleFactor {
        func describe() -> String
        func adjust(_ item: OrderSetSchedule, value: Double) -> Double
    }

    final class RoundingOrderSetScheduleAdjuster: OrderSetScheduleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredOrderSetScheduleAdjuster: OrderSetScheduleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedOrderSetScheduleAdjuster: OrderSetScheduleFactor {
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

        func adjust(_ item: OrderSetSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleOrderSetScheduleAdjuster: OrderSetScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: OrderSetSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class OrderSetScheduleWeightOffsetAdjuster: OrderSetScheduleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: OrderSetSchedule, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class CapOrderSetScheduleAdjuster: OrderSetScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the order set schedule steps in order and keeps a trace of each.
    final class OrderSetScheduleEngine {
        var steps: [any OrderSetScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OrderSetSchedule) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetScheduleFactor = steps[index]
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

        func evaluateAll(_ items: [OrderSetSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOrderSetScheduleEngine(_ flags: Kit.Flags.Registry) -> OrderSetScheduleEngine {
        return OrderSetScheduleEngine(
            steps: [
                RoundingOrderSetScheduleAdjuster(step: 0.25),
                TieredOrderSetScheduleAdjuster(
                    bounds: [6348.0, 8061.0, 8119.0, 8315.0],
                    rates: [1.19, 0.96, 0.87, 1.15]
                ),
                FlaggedOrderSetScheduleAdjuster(flags: flags, flag: "order-set-schedule-primary", percent: 2.2),
                TitleOrderSetScheduleAdjuster(factors: ["south": 0.94]),
                OrderSetScheduleWeightOffsetAdjuster(weight: 0.05),
                CapOrderSetScheduleAdjuster(cap: 16020.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 99889.4
        )
    }
}
