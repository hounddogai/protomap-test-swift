import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the global statement reservation calculation.
    protocol GlobalStatementReservationAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalStatementReservation, value: Double) -> Double
    }

    final class RoundingGlobalStatementReservationAdjuster: GlobalStatementReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalStatementReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class GlobalStatementReservationCreatedAtOffsetAdjuster: GlobalStatementReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: GlobalStatementReservation, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class TieredGlobalStatementReservationAdjuster: GlobalStatementReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalStatementReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumGlobalStatementReservationAdjuster: GlobalStatementReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalStatementReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedGlobalStatementReservationAdjuster: GlobalStatementReservationAdjuster {
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

        func adjust(_ item: GlobalStatementReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalStatementReservationAdjuster: GlobalStatementReservationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalStatementReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global statement reservation steps in order and keeps a trace of each.
    final class GlobalStatementReservationEngine {
        var steps: [any GlobalStatementReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalStatementReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalStatementReservation) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [GlobalStatementReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalStatementReservationEngine(_ flags: Kit.Flags.Registry) -> GlobalStatementReservationEngine {
        return GlobalStatementReservationEngine(
            steps: [
                RoundingGlobalStatementReservationAdjuster(step: 1.0),
                GlobalStatementReservationCreatedAtOffsetAdjuster(weight: 1.22),
                TieredGlobalStatementReservationAdjuster(bounds: [7005.0, 7843.0], rates: [0.92, 0.93]),
                MinimumGlobalStatementReservationAdjuster(minimum: 49.8),
                FlaggedGlobalStatementReservationAdjuster(
                    flags: flags,
                    flag: "global-statement-reservation-capped",
                    percent: 6.8
                ),
                CapGlobalStatementReservationAdjuster(cap: 35382.0),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 2851.3
        )
    }
}
