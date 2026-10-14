import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual substitution reservation calculation.
    protocol ManualSubstitutionReservationAdjuster {
        func describe() -> String
        func adjust(_ item: ManualSubstitutionReservation, value: Double) -> Double
    }

    final class FlaggedManualSubstitutionReservationAdjuster: ManualSubstitutionReservationAdjuster {
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

        func adjust(_ item: ManualSubstitutionReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualSubstitutionReservationAdjuster: ManualSubstitutionReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualSubstitutionReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapManualSubstitutionReservationAdjuster: ManualSubstitutionReservationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualSubstitutionReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual substitution reservation steps in order and keeps a trace of each.
    final class ManualSubstitutionReservationEngine {
        var steps: [any ManualSubstitutionReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualSubstitutionReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualSubstitutionReservation) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [ManualSubstitutionReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualSubstitutionReservationEngine(_ flags: Kit.Flags.Registry) -> ManualSubstitutionReservationEngine {
        return ManualSubstitutionReservationEngine(
            steps: [
                FlaggedManualSubstitutionReservationAdjuster(
                    flags: flags,
                    flag: "manual-substitution-reservation-pending",
                    percent: 0.9
                ),
                TieredManualSubstitutionReservationAdjuster(bounds: [1160.0, 5336.0], rates: [0.89, 0.99]),
                CapManualSubstitutionReservationAdjuster(cap: 18180.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 46665.5
        )
    }
}
