import AcmePlatform
import Foundation

extension Labs {
    /// One step of the regional reference range slot calculation.
    protocol RegionalReferenceRangeSlotFactor {
        func describe() -> String
        func adjust(_ item: RegionalReferenceRangeSlot, value: Double) -> Double
    }

    final class NameRegionalReferenceRangeSlotAdjuster: RegionalReferenceRangeSlotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RegionalReferenceRangeSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRegionalReferenceRangeSlotAdjuster: RegionalReferenceRangeSlotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalReferenceRangeSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRegionalReferenceRangeSlotAdjuster: RegionalReferenceRangeSlotFactor {
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

        func adjust(_ item: RegionalReferenceRangeSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalReferenceRangeSlotAdjuster: RegionalReferenceRangeSlotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalReferenceRangeSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRegionalReferenceRangeSlotAdjuster: RegionalReferenceRangeSlotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalReferenceRangeSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional reference range slot steps in order and keeps a trace of each.
    final class RegionalReferenceRangeSlotEngine {
        var steps: [any RegionalReferenceRangeSlotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalReferenceRangeSlotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalReferenceRangeSlot) -> Double {
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

        func evaluateAll(_ items: [RegionalReferenceRangeSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalReferenceRangeSlotEngine(_ flags: Kit.Flags.Registry) -> RegionalReferenceRangeSlotEngine {
        return RegionalReferenceRangeSlotEngine(
            steps: [
                NameRegionalReferenceRangeSlotAdjuster(factors: ["west": 1.04]),
                CapRegionalReferenceRangeSlotAdjuster(cap: 33444.0),
                FlaggedRegionalReferenceRangeSlotAdjuster(
                    flags: flags,
                    flag: "regional-reference-range-slot-manual",
                    percent: -7.1
                ),
                TieredRegionalReferenceRangeSlotAdjuster(bounds: [4380.0, 4822.0, 6862.0], rates: [0.83, 0.84, 0.88]),
                PercentRegionalReferenceRangeSlotAdjuster(percent: -21.6),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 57574.2
        )
    }
}
