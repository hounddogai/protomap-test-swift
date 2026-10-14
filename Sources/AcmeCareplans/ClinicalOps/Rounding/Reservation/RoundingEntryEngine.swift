import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding entry calculation.
    protocol RoundingEntryFactor {
        func describe() -> String
        func adjust(_ item: RoundingEntry, value: Double) -> Double
    }

    final class TieredRoundingEntryAdjuster: RoundingEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RoundingEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRoundingEntryAdjuster: RoundingEntryFactor {
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

        func adjust(_ item: RoundingEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRoundingEntryAdjuster: RoundingEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingEntryAcuityOffsetAdjuster: RoundingEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: RoundingEntry, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class SegmentRoundingEntryAdjuster: RoundingEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: RoundingEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rounding entry steps in order and keeps a trace of each.
    final class RoundingEntryEngine {
        var steps: [any RoundingEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RoundingEntry) -> Double {
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

        func evaluateAll(_ items: [RoundingEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRoundingEntryEngine(_ flags: Kit.Flags.Registry) -> RoundingEntryEngine {
        return RoundingEntryEngine(
            steps: [
                TieredRoundingEntryAdjuster(bounds: [3888.0, 4511.0, 5513.0], rates: [1.01, 0.97, 0.88]),
                FlaggedRoundingEntryAdjuster(flags: flags, flag: "rounding-entry-scheduled", percent: 6.1),
                CapRoundingEntryAdjuster(cap: 45396.0),
                RoundingEntryAcuityOffsetAdjuster(weight: 1.5),
                SegmentRoundingEntryAdjuster(factors: ["north": 1.29, "west": 1.26, "east": 0.76]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 67113.4
        )
    }
}
