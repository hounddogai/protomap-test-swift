import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set reservation calculation.
    protocol OrderSetReservationFactor {
        func describe() -> String
        func adjust(_ item: OrderSetReservation, value: Double) -> Double
    }

    final class PercentOrderSetReservationAdjuster: OrderSetReservationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapOrderSetReservationAdjuster: OrderSetReservationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class OrderSetReservationDiscountOffsetAdjuster: OrderSetReservationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: OrderSetReservation, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class RoundingOrderSetReservationAdjuster: OrderSetReservationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SourceOrderSetReservationAdjuster: OrderSetReservationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: OrderSetReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedOrderSetReservationAdjuster: OrderSetReservationFactor {
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

        func adjust(_ item: OrderSetReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the order set reservation steps in order and keeps a trace of each.
    final class OrderSetReservationEngine {
        var steps: [any OrderSetReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OrderSetReservation) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetReservationFactor = steps[index]
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

        func evaluateAll(_ items: [OrderSetReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOrderSetReservationEngine(_ flags: Kit.Flags.Registry) -> OrderSetReservationEngine {
        return OrderSetReservationEngine(
            steps: [
                PercentOrderSetReservationAdjuster(percent: -3.6),
                CapOrderSetReservationAdjuster(cap: 42991.0),
                OrderSetReservationDiscountOffsetAdjuster(weight: 0.89),
                RoundingOrderSetReservationAdjuster(step: 0.1),
                SourceOrderSetReservationAdjuster(factors: ["retail": 1.2, "west": 1.12]),
                FlaggedOrderSetReservationAdjuster(flags: flags, flag: "order-set-reservation-regional", percent: 5.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 61559.7
        )
    }
}
