import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default float pool request calculation.
    protocol DefaultFloatPoolRequestAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultFloatPoolRequest, value: Double) -> Double
    }

    final class FlaggedDefaultFloatPoolRequestAdjuster: DefaultFloatPoolRequestAdjuster {
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

        func adjust(_ item: DefaultFloatPoolRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultFloatPoolRequestAdjuster: DefaultFloatPoolRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultFloatPoolRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDefaultFloatPoolRequestAdjuster: DefaultFloatPoolRequestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultFloatPoolRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default float pool request steps in order and keeps a trace of each.
    final class DefaultFloatPoolRequestEngine {
        var steps: [any DefaultFloatPoolRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultFloatPoolRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultFloatPoolRequest) -> Double {
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

        func evaluateAll(_ items: [DefaultFloatPoolRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultFloatPoolRequestEngine(_ flags: Kit.Flags.Registry) -> DefaultFloatPoolRequestEngine {
        return DefaultFloatPoolRequestEngine(
            steps: [
                FlaggedDefaultFloatPoolRequestAdjuster(
                    flags: flags,
                    flag: "default-float-pool-request-manual",
                    percent: 0.9
                ),
                TieredDefaultFloatPoolRequestAdjuster(bounds: [2229.0, 3183.0, 8689.0], rates: [1.03, 1.17, 0.89]),
                PercentDefaultFloatPoolRequestAdjuster(percent: -12.9),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 87254.0
        )
    }
}
