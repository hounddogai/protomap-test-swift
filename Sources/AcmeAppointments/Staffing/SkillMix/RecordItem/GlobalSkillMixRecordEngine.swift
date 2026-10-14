import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global skill mix record calculation.
    protocol GlobalSkillMixRecordFactor {
        func describe() -> String
        func adjust(_ item: GlobalSkillMixRecord, value: Double) -> Double
    }

    final class CapGlobalSkillMixRecordAdjuster: GlobalSkillMixRecordFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalSkillMixRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumGlobalSkillMixRecordAdjuster: GlobalSkillMixRecordFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalSkillMixRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredGlobalSkillMixRecordAdjuster: GlobalSkillMixRecordFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalSkillMixRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalSkillMixRecordAdjuster: GlobalSkillMixRecordFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalSkillMixRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global skill mix record steps in order and keeps a trace of each.
    final class GlobalSkillMixRecordEngine {
        var steps: [any GlobalSkillMixRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalSkillMixRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalSkillMixRecord) -> Double {
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

        func evaluateAll(_ items: [GlobalSkillMixRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalSkillMixRecordEngine() -> GlobalSkillMixRecordEngine {
        return GlobalSkillMixRecordEngine(
            steps: [
                CapGlobalSkillMixRecordAdjuster(cap: 9353.0),
                MinimumGlobalSkillMixRecordAdjuster(minimum: 38.5),
                TieredGlobalSkillMixRecordAdjuster(bounds: [4022.0, 7647.0], rates: [0.92, 1.13]),
                PercentGlobalSkillMixRecordAdjuster(percent: -15.4),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 91026.4
        )
    }
}
