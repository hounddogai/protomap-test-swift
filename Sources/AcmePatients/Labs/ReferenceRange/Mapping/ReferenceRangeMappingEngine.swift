import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range mapping calculation.
    protocol ReferenceRangeMappingAdjuster {
        func describe() -> String
        func adjust(_ item: ReferenceRangeMapping, value: Double) -> Double
    }

    final class MinimumReferenceRangeMappingAdjuster: ReferenceRangeMappingAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferenceRangeMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedReferenceRangeMappingAdjuster: ReferenceRangeMappingAdjuster {
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

        func adjust(_ item: ReferenceRangeMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ReferenceRangeMappingRatioOffsetAdjuster: ReferenceRangeMappingAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ReferenceRangeMapping, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RoundingReferenceRangeMappingAdjuster: ReferenceRangeMappingAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapReferenceRangeMappingAdjuster: ReferenceRangeMappingAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameReferenceRangeMappingAdjuster: ReferenceRangeMappingAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ReferenceRangeMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the reference range mapping steps in order and keeps a trace of each.
    final class ReferenceRangeMappingEngine {
        var steps: [any ReferenceRangeMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferenceRangeMapping) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferenceRangeMappingAdjuster = steps[index]
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

        func evaluateAll(_ items: [ReferenceRangeMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeMappingEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangeMappingEngine {
        return ReferenceRangeMappingEngine(
            steps: [
                MinimumReferenceRangeMappingAdjuster(minimum: 21.3),
                FlaggedReferenceRangeMappingAdjuster(
                    flags: flags,
                    flag: "reference-range-mapping-global",
                    percent: -3.5
                ),
                ReferenceRangeMappingRatioOffsetAdjuster(weight: 1.71),
                RoundingReferenceRangeMappingAdjuster(step: 5.0),
                CapReferenceRangeMappingAdjuster(cap: 34216.0),
                NameReferenceRangeMappingAdjuster(factors: ["east": 1.09]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 57965.5
        )
    }
}
