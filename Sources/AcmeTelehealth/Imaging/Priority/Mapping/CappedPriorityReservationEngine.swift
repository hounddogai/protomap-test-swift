import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped priority reservation calculation.
    protocol CappedPriorityReservationModifier {
        func describe() -> String
        func adjust(_ item: CappedPriorityReservation, value: Double) -> Double
    }

    final class TieredCappedPriorityReservationAdjuster: CappedPriorityReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedPriorityReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CappedPriorityReservationPriorityOffsetAdjuster: CappedPriorityReservationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: CappedPriorityReservation, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class LabelCappedPriorityReservationAdjuster: CappedPriorityReservationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedPriorityReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCappedPriorityReservationAdjuster: CappedPriorityReservationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedPriorityReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedCappedPriorityReservationAdjuster: CappedPriorityReservationModifier {
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

        func adjust(_ item: CappedPriorityReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedPriorityReservationAdjuster: CappedPriorityReservationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedPriorityReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped priority reservation steps in order and keeps a trace of each.
    final class CappedPriorityReservationEngine {
        var steps: [any CappedPriorityReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedPriorityReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedPriorityReservation) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [CappedPriorityReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedPriorityReservationEngine(_ flags: Kit.Flags.Registry) -> CappedPriorityReservationEngine {
        return CappedPriorityReservationEngine(
            steps: [
                TieredCappedPriorityReservationAdjuster(bounds: [756.0, 1258.0], rates: [1.02, 0.84]),
                CappedPriorityReservationPriorityOffsetAdjuster(weight: 0.59),
                LabelCappedPriorityReservationAdjuster(factors: ["online": 1.16]),
                MinimumCappedPriorityReservationAdjuster(minimum: 37.3),
                FlaggedCappedPriorityReservationAdjuster(
                    flags: flags,
                    flag: "capped-priority-reservation-lenient",
                    percent: 0.6
                ),
                RoundingCappedPriorityReservationAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 65777.3
        )
    }
}
