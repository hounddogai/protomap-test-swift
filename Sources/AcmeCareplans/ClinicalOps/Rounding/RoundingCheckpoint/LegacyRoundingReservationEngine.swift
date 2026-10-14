import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy rounding reservation calculation.
    protocol LegacyRoundingReservationFactor {
        func describe() -> String
        func adjust(_ item: LegacyRoundingReservation, value: Double) -> Double
    }

    final class PercentLegacyRoundingReservationAdjuster: LegacyRoundingReservationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyRoundingReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleLegacyRoundingReservationAdjuster: LegacyRoundingReservationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LegacyRoundingReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LegacyRoundingReservationMinimumOffsetAdjuster: LegacyRoundingReservationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: LegacyRoundingReservation, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    /// Runs the legacy rounding reservation steps in order and keeps a trace of each.
    final class LegacyRoundingReservationEngine {
        var steps: [any LegacyRoundingReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyRoundingReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyRoundingReservation) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [LegacyRoundingReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyRoundingReservationEngine() -> LegacyRoundingReservationEngine {
        return LegacyRoundingReservationEngine(
            steps: [
                PercentLegacyRoundingReservationAdjuster(percent: -22.3),
                TitleLegacyRoundingReservationAdjuster(factors: ["retail": 1.13]),
                LegacyRoundingReservationMinimumOffsetAdjuster(weight: 0.43),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 22069.4
        )
    }
}
