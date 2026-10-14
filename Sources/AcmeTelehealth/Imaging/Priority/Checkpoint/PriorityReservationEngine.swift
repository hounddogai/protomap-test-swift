import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority reservation calculation.
    protocol PriorityReservationAdjuster {
        func describe() -> String
        func adjust(_ item: PriorityReservation, value: Double) -> Double
    }

    final class PercentPriorityReservationAdjuster: PriorityReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPriorityReservationAdjuster: PriorityReservationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PriorityReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PriorityReservationCeilingOffsetAdjuster: PriorityReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: PriorityReservation, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class TieredPriorityReservationAdjuster: PriorityReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPriorityReservationAdjuster: PriorityReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPriorityReservationAdjuster: PriorityReservationAdjuster {
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

        func adjust(_ item: PriorityReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the priority reservation steps in order and keeps a trace of each.
    final class PriorityReservationEngine {
        var steps: [any PriorityReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PriorityReservation) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [PriorityReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPriorityReservationEngine(_ flags: Kit.Flags.Registry) -> PriorityReservationEngine {
        return PriorityReservationEngine(
            steps: [
                PercentPriorityReservationAdjuster(percent: -14.3),
                CapPriorityReservationAdjuster(cap: 26633.0),
                PriorityReservationCeilingOffsetAdjuster(weight: 1.53),
                TieredPriorityReservationAdjuster(
                    bounds: [1764.0, 3871.0, 6189.0, 9850.0],
                    rates: [1.05, 0.82, 0.85, 0.9]
                ),
                RoundingPriorityReservationAdjuster(step: 0.05),
                FlaggedPriorityReservationAdjuster(flags: flags, flag: "priority-reservation-global", percent: 0.1),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 28868.1
        )
    }
}
