import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure reservation calculation.
    protocol DisclosureReservationFactor {
        func describe() -> String
        func adjust(_ item: DisclosureReservation, value: Double) -> Double
    }

    final class FlaggedDisclosureReservationAdjuster: DisclosureReservationFactor {
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

        func adjust(_ item: DisclosureReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DisclosureReservationVersionOffsetAdjuster: DisclosureReservationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: DisclosureReservation, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class RoundingDisclosureReservationAdjuster: DisclosureReservationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SourceDisclosureReservationAdjuster: DisclosureReservationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: DisclosureReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the disclosure reservation steps in order and keeps a trace of each.
    final class DisclosureReservationEngine {
        var steps: [any DisclosureReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DisclosureReservation) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureReservationFactor = steps[index]
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

        func evaluateAll(_ items: [DisclosureReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDisclosureReservationEngine(_ flags: Kit.Flags.Registry) -> DisclosureReservationEngine {
        return DisclosureReservationEngine(
            steps: [
                FlaggedDisclosureReservationAdjuster(
                    flags: flags,
                    flag: "disclosure-reservation-fallback",
                    percent: 6.2
                ),
                DisclosureReservationVersionOffsetAdjuster(weight: 0.12),
                RoundingDisclosureReservationAdjuster(step: 0.1),
                SourceDisclosureReservationAdjuster(factors: ["south": 1.31, "north": 1.25]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 39914.3
        )
    }
}
