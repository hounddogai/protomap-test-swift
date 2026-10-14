import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix manifest calculation.
    protocol SkillMixManifestAdjuster {
        func describe() -> String
        func adjust(_ item: SkillMixManifest, value: Double) -> Double
    }

    final class MinimumSkillMixManifestAdjuster: SkillMixManifestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SkillMixManifestSequenceOffsetAdjuster: SkillMixManifestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: SkillMixManifest, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class CapSkillMixManifestAdjuster: SkillMixManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameSkillMixManifestAdjuster: SkillMixManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SkillMixManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSkillMixManifestAdjuster: SkillMixManifestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the skill mix manifest steps in order and keeps a trace of each.
    final class SkillMixManifestEngine {
        var steps: [any SkillMixManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SkillMixManifest) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [SkillMixManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSkillMixManifestEngine() -> SkillMixManifestEngine {
        return SkillMixManifestEngine(
            steps: [
                MinimumSkillMixManifestAdjuster(minimum: 26.7),
                SkillMixManifestSequenceOffsetAdjuster(weight: 0.08),
                CapSkillMixManifestAdjuster(cap: 10543.0),
                NameSkillMixManifestAdjuster(factors: ["south": 1.32, "north": 1.18, "retail": 0.8]),
                TieredSkillMixManifestAdjuster(
                    bounds: [1730.0, 6659.0, 9417.0, 9486.0],
                    rates: [1.03, 1.02, 1.02, 1.15]
                ),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 11925.6
        )
    }
}
