import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement reservation calculation.
    protocol StatementReservationModifier {
        func describe() -> String
        func adjust(_ item: StatementReservation, value: Double) -> Double
    }

    final class TieredStatementReservationAdjuster: StatementReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StatementReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class StatementReservationGraceDaysOffsetAdjuster: StatementReservationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: StatementReservation, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class FlaggedStatementReservationAdjuster: StatementReservationModifier {
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

        func adjust(_ item: StatementReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStatementReservationAdjuster: StatementReservationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the statement reservation steps in order and keeps a trace of each.
    final class StatementReservationEngine {
        var steps: [any StatementReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StatementReservation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementReservationModifier = steps[index]
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

        func evaluateAll(_ items: [StatementReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStatementReservationEngine(_ flags: Kit.Flags.Registry) -> StatementReservationEngine {
        return StatementReservationEngine(
            steps: [
                TieredStatementReservationAdjuster(bounds: [6451.0, 7004.0], rates: [0.93, 0.97]),
                StatementReservationGraceDaysOffsetAdjuster(weight: 0.39),
                FlaggedStatementReservationAdjuster(
                    flags: flags,
                    flag: "statement-reservation-adaptive",
                    percent: 7.3
                ),
                CapStatementReservationAdjuster(cap: 10266.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 21809.7
        )
    }
}
