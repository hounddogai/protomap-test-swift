import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the tiered cleaning reservation calculation.
    protocol TieredCleaningReservationModifier {
        func describe() -> String
        func adjust(_ item: TieredCleaningReservation, value: Double) -> Double
    }

    final class CountryTieredCleaningReservationAdjuster: TieredCleaningReservationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: TieredCleaningReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredCleaningReservationAdjuster: TieredCleaningReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredCleaningReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TieredCleaningReservationCreatedAtOffsetAdjuster: TieredCleaningReservationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: TieredCleaningReservation, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class CapTieredCleaningReservationAdjuster: TieredCleaningReservationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredCleaningReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered cleaning reservation steps in order and keeps a trace of each.
    final class TieredCleaningReservationEngine {
        var steps: [any TieredCleaningReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredCleaningReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredCleaningReservation) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredCleaningReservationModifier = steps[index]
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

        func evaluateAll(_ items: [TieredCleaningReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredCleaningReservationEngine() -> TieredCleaningReservationEngine {
        return TieredCleaningReservationEngine(
            steps: [
                CountryTieredCleaningReservationAdjuster(factors: ["retail": 1.15, "south": 0.84, "north": 1.15]),
                TieredTieredCleaningReservationAdjuster(bounds: [317.0, 3022.0], rates: [1.07, 0.94]),
                TieredCleaningReservationCreatedAtOffsetAdjuster(weight: 1.45),
                CapTieredCleaningReservationAdjuster(cap: 37057.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 41381.8
        )
    }
}
