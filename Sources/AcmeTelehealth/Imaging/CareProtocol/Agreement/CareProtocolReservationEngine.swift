import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol reservation calculation.
    protocol CareProtocolReservationAdjuster {
        func describe() -> String
        func adjust(_ item: CareProtocolReservation, value: Double) -> Double
    }

    final class MinimumCareProtocolReservationAdjuster: CareProtocolReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleCareProtocolReservationAdjuster: CareProtocolReservationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CareProtocolReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCareProtocolReservationAdjuster: CareProtocolReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CareProtocolReservationCreatedAtOffsetAdjuster: CareProtocolReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: CareProtocolReservation, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class CapCareProtocolReservationAdjuster: CareProtocolReservationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCareProtocolReservationAdjuster: CareProtocolReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care protocol reservation steps in order and keeps a trace of each.
    final class CareProtocolReservationEngine {
        var steps: [any CareProtocolReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolReservation) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [CareProtocolReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolReservationEngine() -> CareProtocolReservationEngine {
        return CareProtocolReservationEngine(
            steps: [
                MinimumCareProtocolReservationAdjuster(minimum: 44.8),
                TitleCareProtocolReservationAdjuster(factors: ["central": 1.21, "east": 1.04]),
                RoundingCareProtocolReservationAdjuster(step: 0.25),
                CareProtocolReservationCreatedAtOffsetAdjuster(weight: 1.87),
                CapCareProtocolReservationAdjuster(cap: 6108.0),
                PercentCareProtocolReservationAdjuster(percent: -10.3),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 29699.4
        )
    }
}
