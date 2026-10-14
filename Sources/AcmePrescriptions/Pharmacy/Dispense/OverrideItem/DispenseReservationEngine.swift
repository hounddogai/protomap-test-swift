import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense reservation calculation.
    protocol DispenseReservationFactor {
        func describe() -> String
        func adjust(_ item: DispenseReservation, value: Double) -> Double
    }

    final class RoundingDispenseReservationAdjuster: DispenseReservationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentDispenseReservationAdjuster: DispenseReservationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDispenseReservationAdjuster: DispenseReservationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDispenseReservationAdjuster: DispenseReservationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispenseReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the dispense reservation steps in order and keeps a trace of each.
    final class DispenseReservationEngine {
        var steps: [any DispenseReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DispenseReservation) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseReservationFactor = steps[index]
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

        func evaluateAll(_ items: [DispenseReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDispenseReservationEngine() -> DispenseReservationEngine {
        return DispenseReservationEngine(
            steps: [
                RoundingDispenseReservationAdjuster(step: 5.0),
                PercentDispenseReservationAdjuster(percent: 4.5),
                CapDispenseReservationAdjuster(cap: 33362.0),
                TieredDispenseReservationAdjuster(bounds: [1708.0, 7448.0], rates: [1.12, 1.08]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 49235.2
        )
    }
}
