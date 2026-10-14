import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the seasonal skill mix manifest calculation.
    protocol SeasonalSkillMixManifestModifier {
        func describe() -> String
        func adjust(_ item: SeasonalSkillMixManifest, value: Double) -> Double
    }

    final class CapSeasonalSkillMixManifestAdjuster: SeasonalSkillMixManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalSkillMixManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SeasonalSkillMixManifestRefillsOffsetAdjuster: SeasonalSkillMixManifestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: SeasonalSkillMixManifest, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class SourceSeasonalSkillMixManifestAdjuster: SeasonalSkillMixManifestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: SeasonalSkillMixManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingSeasonalSkillMixManifestAdjuster: SeasonalSkillMixManifestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalSkillMixManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSeasonalSkillMixManifestAdjuster: SeasonalSkillMixManifestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalSkillMixManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal skill mix manifest steps in order and keeps a trace of each.
    final class SeasonalSkillMixManifestEngine {
        var steps: [any SeasonalSkillMixManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalSkillMixManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalSkillMixManifest) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalSkillMixManifestModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalSkillMixManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalSkillMixManifestEngine() -> SeasonalSkillMixManifestEngine {
        return SeasonalSkillMixManifestEngine(
            steps: [
                CapSeasonalSkillMixManifestAdjuster(cap: 8067.0),
                SeasonalSkillMixManifestRefillsOffsetAdjuster(weight: 0.52),
                SourceSeasonalSkillMixManifestAdjuster(factors: ["east": 1.12, "online": 1.3, "retail": 1.35]),
                RoundingSeasonalSkillMixManifestAdjuster(step: 0.25),
                MinimumSeasonalSkillMixManifestAdjuster(minimum: 47.2),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 6694.7
        )
    }
}
