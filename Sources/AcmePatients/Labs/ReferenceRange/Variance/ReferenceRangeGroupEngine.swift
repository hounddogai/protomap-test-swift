import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range group calculation.
    protocol ReferenceRangeGroupFactor {
        func describe() -> String
        func adjust(_ item: ReferenceRangeGroup, value: Double) -> Double
    }

    final class RoundingReferenceRangeGroupAdjuster: ReferenceRangeGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ReferenceRangeGroupStartsAtOffsetAdjuster: ReferenceRangeGroupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: ReferenceRangeGroup, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class TieredReferenceRangeGroupAdjuster: ReferenceRangeGroupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedReferenceRangeGroupAdjuster: ReferenceRangeGroupFactor {
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

        func adjust(_ item: ReferenceRangeGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelReferenceRangeGroupAdjuster: ReferenceRangeGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ReferenceRangeGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the reference range group steps in order and keeps a trace of each.
    final class ReferenceRangeGroupEngine {
        var steps: [any ReferenceRangeGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferenceRangeGroup) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [ReferenceRangeGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeGroupEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangeGroupEngine {
        return ReferenceRangeGroupEngine(
            steps: [
                RoundingReferenceRangeGroupAdjuster(step: 0.5),
                ReferenceRangeGroupStartsAtOffsetAdjuster(weight: 1.72),
                TieredReferenceRangeGroupAdjuster(bounds: [4296.0, 9110.0], rates: [0.95, 1.14]),
                FlaggedReferenceRangeGroupAdjuster(flags: flags, flag: "reference-range-group-rolling", percent: 4.4),
                LabelReferenceRangeGroupAdjuster(factors: ["online": 0.75, "north": 1.3, "retail": 1.14]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 27237.2
        )
    }
}
