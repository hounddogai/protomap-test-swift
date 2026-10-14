import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary skill mix mapping calculation.
    protocol PrimarySkillMixMappingFactor {
        func describe() -> String
        func adjust(_ item: PrimarySkillMixMapping, value: Double) -> Double
    }

    final class MinimumPrimarySkillMixMappingAdjuster: PrimarySkillMixMappingFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimarySkillMixMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PrimarySkillMixMappingRefillsOffsetAdjuster: PrimarySkillMixMappingFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: PrimarySkillMixMapping, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class RoundingPrimarySkillMixMappingAdjuster: PrimarySkillMixMappingFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimarySkillMixMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPrimarySkillMixMappingAdjuster: PrimarySkillMixMappingFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimarySkillMixMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourcePrimarySkillMixMappingAdjuster: PrimarySkillMixMappingFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: PrimarySkillMixMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPrimarySkillMixMappingAdjuster: PrimarySkillMixMappingFactor {
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

        func adjust(_ item: PrimarySkillMixMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary skill mix mapping steps in order and keeps a trace of each.
    final class PrimarySkillMixMappingEngine {
        var steps: [any PrimarySkillMixMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimarySkillMixMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimarySkillMixMapping) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [PrimarySkillMixMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimarySkillMixMappingEngine(_ flags: Kit.Flags.Registry) -> PrimarySkillMixMappingEngine {
        return PrimarySkillMixMappingEngine(
            steps: [
                MinimumPrimarySkillMixMappingAdjuster(minimum: 13.1),
                PrimarySkillMixMappingRefillsOffsetAdjuster(weight: 1.23),
                RoundingPrimarySkillMixMappingAdjuster(step: 1.0),
                TieredPrimarySkillMixMappingAdjuster(bounds: [3983.0, 6295.0], rates: [1.15, 1.14]),
                SourcePrimarySkillMixMappingAdjuster(factors: ["east": 1.33, "central": 1.06, "north": 1.32]),
                FlaggedPrimarySkillMixMappingAdjuster(
                    flags: flags,
                    flag: "primary-skill-mix-mapping-fallback",
                    percent: 2.1
                ),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 95119.9
        )
    }
}
