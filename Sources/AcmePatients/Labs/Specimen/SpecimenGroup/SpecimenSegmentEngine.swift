import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen segment calculation.
    protocol SpecimenSegmentModifier {
        func describe() -> String
        func adjust(_ item: SpecimenSegment, value: Double) -> Double
    }

    final class SpecimenSegmentWeightOffsetAdjuster: SpecimenSegmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: SpecimenSegment, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class FlaggedSpecimenSegmentAdjuster: SpecimenSegmentModifier {
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

        func adjust(_ item: SpecimenSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSpecimenSegmentAdjuster: SpecimenSegmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSpecimenSegmentAdjuster: SpecimenSegmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the specimen segment steps in order and keeps a trace of each.
    final class SpecimenSegmentEngine {
        var steps: [any SpecimenSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SpecimenSegment) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [SpecimenSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSpecimenSegmentEngine(_ flags: Kit.Flags.Registry) -> SpecimenSegmentEngine {
        return SpecimenSegmentEngine(
            steps: [
                SpecimenSegmentWeightOffsetAdjuster(weight: 1.76),
                FlaggedSpecimenSegmentAdjuster(flags: flags, flag: "specimen-segment-regional", percent: -6.4),
                TieredSpecimenSegmentAdjuster(
                    bounds: [154.0, 3898.0, 4470.0, 8853.0],
                    rates: [1.09, 1.11, 1.17, 1.13]
                ),
                RoundingSpecimenSegmentAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 52463.0
        )
    }
}
