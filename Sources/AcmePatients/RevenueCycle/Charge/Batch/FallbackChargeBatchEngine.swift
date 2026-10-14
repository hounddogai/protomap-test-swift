import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback charge batch calculation.
    protocol FallbackChargeBatchFactor {
        func describe() -> String
        func adjust(_ item: FallbackChargeBatch, value: Double) -> Double
    }

    final class FacilityFallbackChargeBatchAdjuster: FallbackChargeBatchFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: FallbackChargeBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFallbackChargeBatchAdjuster: FallbackChargeBatchFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackChargeBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFallbackChargeBatchAdjuster: FallbackChargeBatchFactor {
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

        func adjust(_ item: FallbackChargeBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback charge batch steps in order and keeps a trace of each.
    final class FallbackChargeBatchEngine {
        var steps: [any FallbackChargeBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackChargeBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackChargeBatch) -> Double {
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

        func evaluateAll(_ items: [FallbackChargeBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackChargeBatchEngine(_ flags: Kit.Flags.Registry) -> FallbackChargeBatchEngine {
        return FallbackChargeBatchEngine(
            steps: [
                FacilityFallbackChargeBatchAdjuster(factors: ["east": 0.76]),
                TieredFallbackChargeBatchAdjuster(
                    bounds: [17.0, 709.0, 5290.0, 7999.0],
                    rates: [0.83, 1.2, 1.1, 0.92]
                ),
                FlaggedFallbackChargeBatchAdjuster(
                    flags: flags,
                    flag: "fallback-charge-batch-scheduled",
                    percent: 4.0
                ),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 7910.2
        )
    }
}
