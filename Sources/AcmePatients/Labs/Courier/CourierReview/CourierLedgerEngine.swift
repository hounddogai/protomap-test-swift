import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier ledger calculation.
    protocol CourierLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: CourierLedger, value: Double) -> Double
    }

    final class MinimumCourierLedgerAdjuster: CourierLedgerAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCourierLedgerAdjuster: CourierLedgerAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCourierLedgerAdjuster: CourierLedgerAdjuster {
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

        func adjust(_ item: CourierLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the courier ledger steps in order and keeps a trace of each.
    final class CourierLedgerEngine {
        var steps: [any CourierLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CourierLedger) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [CourierLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCourierLedgerEngine(_ flags: Kit.Flags.Registry) -> CourierLedgerEngine {
        return CourierLedgerEngine(
            steps: [
                MinimumCourierLedgerAdjuster(minimum: 44.9),
                TieredCourierLedgerAdjuster(bounds: [5576.0, 5777.0, 6280.0, 7693.0], rates: [1.12, 1.07, 0.88, 1.08]),
                FlaggedCourierLedgerAdjuster(flags: flags, flag: "courier-ledger-adaptive", percent: -5.7),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 17480.0
        )
    }
}
