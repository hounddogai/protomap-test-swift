import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the default read allocation calculation.
    protocol DefaultReadAllocationFactor {
        func describe() -> String
        func adjust(_ item: DefaultReadAllocation, value: Double) -> Double
    }

    final class PercentDefaultReadAllocationAdjuster: DefaultReadAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultReadAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDefaultReadAllocationAdjuster: DefaultReadAllocationFactor {
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

        func adjust(_ item: DefaultReadAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultReadAllocationRevisionOffsetAdjuster: DefaultReadAllocationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: DefaultReadAllocation, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class TieredDefaultReadAllocationAdjuster: DefaultReadAllocationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultReadAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WardDefaultReadAllocationAdjuster: DefaultReadAllocationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: DefaultReadAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the default read allocation steps in order and keeps a trace of each.
    final class DefaultReadAllocationEngine {
        var steps: [any DefaultReadAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultReadAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultReadAllocation) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultReadAllocationFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultReadAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultReadAllocationEngine(_ flags: Kit.Flags.Registry) -> DefaultReadAllocationEngine {
        return DefaultReadAllocationEngine(
            steps: [
                PercentDefaultReadAllocationAdjuster(percent: -22.1),
                FlaggedDefaultReadAllocationAdjuster(
                    flags: flags,
                    flag: "default-read-allocation-lenient",
                    percent: 6.8
                ),
                DefaultReadAllocationRevisionOffsetAdjuster(weight: 0.44),
                TieredDefaultReadAllocationAdjuster(
                    bounds: [6733.0, 6793.0, 9277.0, 9728.0],
                    rates: [0.89, 0.95, 1.0, 1.01]
                ),
                WardDefaultReadAllocationAdjuster(factors: ["west": 1.01]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 91403.0
        )
    }
}
