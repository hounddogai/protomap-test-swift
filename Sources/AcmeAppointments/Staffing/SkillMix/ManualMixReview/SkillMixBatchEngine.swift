import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix batch calculation.
    protocol SkillMixBatchAdjuster {
        func describe() -> String
        func adjust(_ item: SkillMixBatch, value: Double) -> Double
    }

    final class TieredSkillMixBatchAdjuster: SkillMixBatchAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapSkillMixBatchAdjuster: SkillMixBatchAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SkillMixBatchMinimumOffsetAdjuster: SkillMixBatchAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: SkillMixBatch, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class FlaggedSkillMixBatchAdjuster: SkillMixBatchAdjuster {
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

        func adjust(_ item: SkillMixBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitSkillMixBatchAdjuster: SkillMixBatchAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: SkillMixBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSkillMixBatchAdjuster: SkillMixBatchAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the skill mix batch steps in order and keeps a trace of each.
    final class SkillMixBatchEngine {
        var steps: [any SkillMixBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SkillMixBatch) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [SkillMixBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSkillMixBatchEngine(_ flags: Kit.Flags.Registry) -> SkillMixBatchEngine {
        return SkillMixBatchEngine(
            steps: [
                TieredSkillMixBatchAdjuster(bounds: [2131.0, 4219.0, 6352.0, 8132.0], rates: [1.05, 0.9, 0.88, 1.03]),
                CapSkillMixBatchAdjuster(cap: 22338.0),
                SkillMixBatchMinimumOffsetAdjuster(weight: 0.84),
                FlaggedSkillMixBatchAdjuster(flags: flags, flag: "skill-mix-batch-regional", percent: 1.0),
                UnitSkillMixBatchAdjuster(factors: ["online": 1.01, "west": 1.27]),
                MinimumSkillMixBatchAdjuster(minimum: 19.1),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 34116.8
        )
    }
}
