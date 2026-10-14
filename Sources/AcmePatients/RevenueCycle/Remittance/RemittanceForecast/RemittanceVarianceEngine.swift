import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance variance calculation.
    protocol RemittanceVarianceStep {
        func describe() -> String
        func adjust(_ item: RemittanceVariance, value: Double) -> Double
    }

    final class FlaggedRemittanceVarianceAdjuster: RemittanceVarianceStep {
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

        func adjust(_ item: RemittanceVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRemittanceVarianceAdjuster: RemittanceVarianceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRemittanceVarianceAdjuster: RemittanceVarianceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the remittance variance steps in order and keeps a trace of each.
    final class RemittanceVarianceEngine {
        var steps: [any RemittanceVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RemittanceVariance) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [RemittanceVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRemittanceVarianceEngine(_ flags: Kit.Flags.Registry) -> RemittanceVarianceEngine {
        return RemittanceVarianceEngine(
            steps: [
                FlaggedRemittanceVarianceAdjuster(flags: flags, flag: "remittance-variance-rolling", percent: -9.9),
                CapRemittanceVarianceAdjuster(cap: 44655.0),
                TieredRemittanceVarianceAdjuster(bounds: [14.0, 3035.0, 3329.0], rates: [1.03, 0.9, 0.99]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 39461.2
        )
    }
}
