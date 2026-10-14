import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding bundle calculation.
    protocol RoundingBundleModifier {
        func describe() -> String
        func adjust(_ item: RoundingBundle, value: Double) -> Double
    }

    final class FlaggedRoundingBundleAdjuster: RoundingBundleModifier {
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

        func adjust(_ item: RoundingBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityRoundingBundleAdjuster: RoundingBundleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RoundingBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRoundingBundleAdjuster: RoundingBundleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RoundingBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RoundingBundlePriorityOffsetAdjuster: RoundingBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: RoundingBundle, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the rounding bundle steps in order and keeps a trace of each.
    final class RoundingBundleEngine {
        var steps: [any RoundingBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RoundingBundle) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [RoundingBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRoundingBundleEngine(_ flags: Kit.Flags.Registry) -> RoundingBundleEngine {
        return RoundingBundleEngine(
            steps: [
                FlaggedRoundingBundleAdjuster(flags: flags, flag: "rounding-bundle-tiered", percent: -9.4),
                FacilityRoundingBundleAdjuster(factors: ["retail": 0.86]),
                RoundingRoundingBundleAdjuster(step: 0.5),
                RoundingBundlePriorityOffsetAdjuster(weight: 0.38),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 98636.0
        )
    }
}
