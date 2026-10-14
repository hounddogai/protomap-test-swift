import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional follow up reservation calculation.
    protocol RegionalFollowUpReservationStep {
        func describe() -> String
        func adjust(_ item: RegionalFollowUpReservation, value: Double) -> Double
    }

    final class RegionalFollowUpReservationCreatedAtOffsetAdjuster: RegionalFollowUpReservationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: RegionalFollowUpReservation, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class PercentRegionalFollowUpReservationAdjuster: RegionalFollowUpReservationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalFollowUpReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalFollowUpReservationAdjuster: RegionalFollowUpReservationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalFollowUpReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRegionalFollowUpReservationAdjuster: RegionalFollowUpReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalFollowUpReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FacilityRegionalFollowUpReservationAdjuster: RegionalFollowUpReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RegionalFollowUpReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional follow up reservation steps in order and keeps a trace of each.
    final class RegionalFollowUpReservationEngine {
        var steps: [any RegionalFollowUpReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalFollowUpReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalFollowUpReservation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalFollowUpReservationStep = steps[index]
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

        func evaluateAll(_ items: [RegionalFollowUpReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalFollowUpReservationEngine() -> RegionalFollowUpReservationEngine {
        return RegionalFollowUpReservationEngine(
            steps: [
                RegionalFollowUpReservationCreatedAtOffsetAdjuster(weight: 1.57),
                PercentRegionalFollowUpReservationAdjuster(percent: 16.4),
                MinimumRegionalFollowUpReservationAdjuster(minimum: 15.1),
                RoundingRegionalFollowUpReservationAdjuster(step: 0.1),
                FacilityRegionalFollowUpReservationAdjuster(factors: ["south": 0.87]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 64367.5
        )
    }
}
