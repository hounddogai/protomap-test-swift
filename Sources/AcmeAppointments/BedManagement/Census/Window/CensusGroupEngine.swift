import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census group calculation.
    protocol CensusGroupStep {
        func describe() -> String
        func adjust(_ item: CensusGroup, value: Double) -> Double
    }

    final class PercentCensusGroupAdjuster: CensusGroupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCensusGroupAdjuster: CensusGroupStep {
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

        func adjust(_ item: CensusGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCensusGroupAdjuster: CensusGroupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CensusGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCensusGroupAdjuster: CensusGroupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CensusGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CensusGroupCapacityOffsetAdjuster: CensusGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: CensusGroup, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the census group steps in order and keeps a trace of each.
    final class CensusGroupEngine {
        var steps: [any CensusGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CensusGroup) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [CensusGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCensusGroupEngine(_ flags: Kit.Flags.Registry) -> CensusGroupEngine {
        return CensusGroupEngine(
            steps: [
                PercentCensusGroupAdjuster(percent: -21.4),
                FlaggedCensusGroupAdjuster(flags: flags, flag: "census-group-primary", percent: -3.9),
                CapCensusGroupAdjuster(cap: 23444.0),
                TieredCensusGroupAdjuster(bounds: [1640.0, 8032.0], rates: [0.81, 1.13]),
                CensusGroupCapacityOffsetAdjuster(weight: 0.19),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 98550.9
        )
    }
}
