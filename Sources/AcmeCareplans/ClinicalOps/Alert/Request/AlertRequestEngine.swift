import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert request calculation.
    protocol AlertRequestFactor {
        func describe() -> String
        func adjust(_ item: AlertRequest, value: Double) -> Double
    }

    final class PercentAlertRequestAdjuster: AlertRequestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAlertRequestAdjuster: AlertRequestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAlertRequestAdjuster: AlertRequestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAlertRequestAdjuster: AlertRequestFactor {
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

        func adjust(_ item: AlertRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAlertRequestAdjuster: AlertRequestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the alert request steps in order and keeps a trace of each.
    final class AlertRequestEngine {
        var steps: [any AlertRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AlertRequest) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [AlertRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAlertRequestEngine(_ flags: Kit.Flags.Registry) -> AlertRequestEngine {
        return AlertRequestEngine(
            steps: [
                PercentAlertRequestAdjuster(percent: 11.3),
                TieredAlertRequestAdjuster(bounds: [80.0, 1240.0, 5076.0, 5272.0], rates: [1.11, 1.16, 0.98, 1.17]),
                MinimumAlertRequestAdjuster(minimum: 1.8),
                FlaggedAlertRequestAdjuster(flags: flags, flag: "alert-request-pending", percent: 5.8),
                CapAlertRequestAdjuster(cap: 34517.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 99163.8
        )
    }
}
