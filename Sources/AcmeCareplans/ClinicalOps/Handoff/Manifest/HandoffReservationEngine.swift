import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff reservation calculation.
    protocol HandoffReservationModifier {
        func describe() -> String
        func adjust(_ item: HandoffReservation, value: Double) -> Double
    }

    final class PercentHandoffReservationAdjuster: HandoffReservationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleHandoffReservationAdjuster: HandoffReservationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: HandoffReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredHandoffReservationAdjuster: HandoffReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapHandoffReservationAdjuster: HandoffReservationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingHandoffReservationAdjuster: HandoffReservationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedHandoffReservationAdjuster: HandoffReservationModifier {
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

        func adjust(_ item: HandoffReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the handoff reservation steps in order and keeps a trace of each.
    final class HandoffReservationEngine {
        var steps: [any HandoffReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: HandoffReservation) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [HandoffReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultHandoffReservationEngine(_ flags: Kit.Flags.Registry) -> HandoffReservationEngine {
        return HandoffReservationEngine(
            steps: [
                PercentHandoffReservationAdjuster(percent: -12.3),
                TitleHandoffReservationAdjuster(factors: ["west": 1.18, "east": 1.15, "south": 1.19]),
                TieredHandoffReservationAdjuster(
                    bounds: [6684.0, 7477.0, 7848.0, 8969.0],
                    rates: [0.81, 1.16, 1.17, 1.19]
                ),
                CapHandoffReservationAdjuster(cap: 45722.0),
                RoundingHandoffReservationAdjuster(step: 5.0),
                FlaggedHandoffReservationAdjuster(flags: flags, flag: "handoff-reservation-scheduled", percent: -2.9),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 32923.8
        )
    }
}
