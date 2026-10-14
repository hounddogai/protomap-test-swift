import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient care gap allocation calculation.
    protocol LenientCareGapAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: LenientCareGapAllocation, value: Double) -> Double
    }

    final class MinimumLenientCareGapAllocationAdjuster: LenientCareGapAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientCareGapAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLenientCareGapAllocationAdjuster: LenientCareGapAllocationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientCareGapAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLenientCareGapAllocationAdjuster: LenientCareGapAllocationAdjuster {
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

        func adjust(_ item: LenientCareGapAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientCareGapAllocationAdjuster: LenientCareGapAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientCareGapAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LocaleLenientCareGapAllocationAdjuster: LenientCareGapAllocationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: LenientCareGapAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient care gap allocation steps in order and keeps a trace of each.
    final class LenientCareGapAllocationEngine {
        var steps: [any LenientCareGapAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCareGapAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientCareGapAllocation) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [LenientCareGapAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientCareGapAllocationEngine(_ flags: Kit.Flags.Registry) -> LenientCareGapAllocationEngine {
        return LenientCareGapAllocationEngine(
            steps: [
                MinimumLenientCareGapAllocationAdjuster(minimum: 45.2),
                CapLenientCareGapAllocationAdjuster(cap: 36535.0),
                FlaggedLenientCareGapAllocationAdjuster(
                    flags: flags,
                    flag: "lenient-care-gap-allocation-pending",
                    percent: -9.9
                ),
                TieredLenientCareGapAllocationAdjuster(
                    bounds: [1480.0, 4347.0, 6026.0, 6510.0],
                    rates: [0.95, 1.0, 0.9, 0.99]
                ),
                LocaleLenientCareGapAllocationAdjuster(factors: ["north": 1.28, "west": 0.73]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 74132.6
        )
    }
}
