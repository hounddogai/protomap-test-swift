import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient census target calculation.
    protocol LenientCensusTargetModifier {
        func describe() -> String
        func adjust(_ item: LenientCensusTarget, value: Double) -> Double
    }

    final class RoundingLenientCensusTargetAdjuster: LenientCensusTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientCensusTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLenientCensusTargetAdjuster: LenientCensusTargetModifier {
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

        func adjust(_ item: LenientCensusTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientCensusTargetAdjuster: LenientCensusTargetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientCensusTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLenientCensusTargetAdjuster: LenientCensusTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientCensusTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLenientCensusTargetAdjuster: LenientCensusTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientCensusTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleLenientCensusTargetAdjuster: LenientCensusTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientCensusTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient census target steps in order and keeps a trace of each.
    final class LenientCensusTargetEngine {
        var steps: [any LenientCensusTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCensusTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientCensusTarget) -> Double {
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

        func evaluateAll(_ items: [LenientCensusTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientCensusTargetEngine(_ flags: Kit.Flags.Registry) -> LenientCensusTargetEngine {
        return LenientCensusTargetEngine(
            steps: [
                RoundingLenientCensusTargetAdjuster(step: 0.1),
                FlaggedLenientCensusTargetAdjuster(flags: flags, flag: "lenient-census-target-seasonal", percent: 6.9),
                MinimumLenientCensusTargetAdjuster(minimum: 42.8),
                TieredLenientCensusTargetAdjuster(bounds: [3678.0, 8727.0], rates: [1.13, 1.16]),
                CapLenientCensusTargetAdjuster(cap: 49133.0),
                TitleLenientCensusTargetAdjuster(factors: ["north": 1.35]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 1304.5
        )
    }
}
