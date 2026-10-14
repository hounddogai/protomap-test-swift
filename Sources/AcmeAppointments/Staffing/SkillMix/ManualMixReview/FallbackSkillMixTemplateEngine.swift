import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback skill mix template calculation.
    protocol FallbackSkillMixTemplateStep {
        func describe() -> String
        func adjust(_ item: FallbackSkillMixTemplate, value: Double) -> Double
    }

    final class TieredFallbackSkillMixTemplateAdjuster: FallbackSkillMixTemplateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackSkillMixTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapFallbackSkillMixTemplateAdjuster: FallbackSkillMixTemplateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackSkillMixTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FallbackSkillMixTemplateVersionOffsetAdjuster: FallbackSkillMixTemplateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: FallbackSkillMixTemplate, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class RoundingFallbackSkillMixTemplateAdjuster: FallbackSkillMixTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackSkillMixTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumFallbackSkillMixTemplateAdjuster: FallbackSkillMixTemplateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackSkillMixTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback skill mix template steps in order and keeps a trace of each.
    final class FallbackSkillMixTemplateEngine {
        var steps: [any FallbackSkillMixTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackSkillMixTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackSkillMixTemplate) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackSkillMixTemplateStep = steps[index]
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

        func evaluateAll(_ items: [FallbackSkillMixTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackSkillMixTemplateEngine() -> FallbackSkillMixTemplateEngine {
        return FallbackSkillMixTemplateEngine(
            steps: [
                TieredFallbackSkillMixTemplateAdjuster(bounds: [4517.0, 8785.0], rates: [0.92, 1.03]),
                CapFallbackSkillMixTemplateAdjuster(cap: 1285.0),
                FallbackSkillMixTemplateVersionOffsetAdjuster(weight: 0.29),
                RoundingFallbackSkillMixTemplateAdjuster(step: 0.1),
                MinimumFallbackSkillMixTemplateAdjuster(minimum: 48.6),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 1933.8
        )
    }
}
