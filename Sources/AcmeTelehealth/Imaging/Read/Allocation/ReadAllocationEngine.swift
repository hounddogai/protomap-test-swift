import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read allocation calculation.
    protocol ReadAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: ReadAllocation, value: Double) -> Double
    }

    final class PercentReadAllocationAdjuster: ReadAllocationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedReadAllocationAdjuster: ReadAllocationAdjuster {
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

        func adjust(_ item: ReadAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumReadAllocationAdjuster: ReadAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReadAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ReadAllocationAcuityOffsetAdjuster: ReadAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: ReadAllocation, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class TieredReadAllocationAdjuster: ReadAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapReadAllocationAdjuster: ReadAllocationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the read allocation steps in order and keeps a trace of each.
    final class ReadAllocationEngine {
        var steps: [any ReadAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReadAllocation) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [ReadAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReadAllocationEngine(_ flags: Kit.Flags.Registry) -> ReadAllocationEngine {
        return ReadAllocationEngine(
            steps: [
                PercentReadAllocationAdjuster(percent: 24.2),
                FlaggedReadAllocationAdjuster(flags: flags, flag: "read-allocation-manual", percent: 0.0),
                MinimumReadAllocationAdjuster(minimum: 4.2),
                ReadAllocationAcuityOffsetAdjuster(weight: 1.95),
                TieredReadAllocationAdjuster(bounds: [268.0, 2207.0, 6030.0], rates: [0.87, 0.87, 1.08]),
                CapReadAllocationAdjuster(cap: 47818.0),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 68461.0
        )
    }
}
