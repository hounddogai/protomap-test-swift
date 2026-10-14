import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance estimate calculation.
    protocol RemittanceEstimateStep {
        func describe() -> String
        func adjust(_ item: RemittanceEstimate, value: Double) -> Double
    }

    final class TieredRemittanceEstimateAdjuster: RemittanceEstimateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRemittanceEstimateAdjuster: RemittanceEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameRemittanceEstimateAdjuster: RemittanceEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RemittanceEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRemittanceEstimateAdjuster: RemittanceEstimateStep {
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

        func adjust(_ item: RemittanceEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRemittanceEstimateAdjuster: RemittanceEstimateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the remittance estimate steps in order and keeps a trace of each.
    final class RemittanceEstimateEngine {
        var steps: [any RemittanceEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RemittanceEstimate) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceEstimateStep = steps[index]
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

        func evaluateAll(_ items: [RemittanceEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRemittanceEstimateEngine(_ flags: Kit.Flags.Registry) -> RemittanceEstimateEngine {
        return RemittanceEstimateEngine(
            steps: [
                TieredRemittanceEstimateAdjuster(bounds: [2825.0, 7871.0], rates: [1.13, 0.91]),
                PercentRemittanceEstimateAdjuster(percent: 6.0),
                NameRemittanceEstimateAdjuster(factors: ["east": 0.87, "retail": 0.8, "south": 1.22]),
                FlaggedRemittanceEstimateAdjuster(flags: flags, flag: "remittance-estimate-manual", percent: -9.7),
                CapRemittanceEstimateAdjuster(cap: 21493.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 67065.8
        )
    }
}
