import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the regional statement reservation calculation.
    protocol RegionalStatementReservationFactor {
        func describe() -> String
        func adjust(_ item: RegionalStatementReservation, value: Double) -> Double
    }

    final class LabelRegionalStatementReservationAdjuster: RegionalStatementReservationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RegionalStatementReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRegionalStatementReservationAdjuster: RegionalStatementReservationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalStatementReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRegionalStatementReservationAdjuster: RegionalStatementReservationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalStatementReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional statement reservation steps in order and keeps a trace of each.
    final class RegionalStatementReservationEngine {
        var steps: [any RegionalStatementReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalStatementReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalStatementReservation) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalStatementReservationFactor = steps[index]
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

        func evaluateAll(_ items: [RegionalStatementReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalStatementReservationEngine() -> RegionalStatementReservationEngine {
        return RegionalStatementReservationEngine(
            steps: [
                LabelRegionalStatementReservationAdjuster(factors: ["online": 1.12, "west": 1.17, "east": 0.99]),
                CapRegionalStatementReservationAdjuster(cap: 865.0),
                MinimumRegionalStatementReservationAdjuster(minimum: 4.1),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 5264.4
        )
    }
}
