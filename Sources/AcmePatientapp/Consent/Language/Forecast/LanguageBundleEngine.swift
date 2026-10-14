import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language bundle calculation.
    protocol LanguageBundleFactor {
        func describe() -> String
        func adjust(_ item: LanguageBundle, value: Double) -> Double
    }

    final class CapLanguageBundleAdjuster: LanguageBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LanguageBundleDosageMgOffsetAdjuster: LanguageBundleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: LanguageBundle, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class RoundingLanguageBundleAdjuster: LanguageBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguageBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameLanguageBundleAdjuster: LanguageBundleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LanguageBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLanguageBundleAdjuster: LanguageBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the language bundle steps in order and keeps a trace of each.
    final class LanguageBundleEngine {
        var steps: [any LanguageBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LanguageBundle) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [LanguageBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLanguageBundleEngine() -> LanguageBundleEngine {
        return LanguageBundleEngine(
            steps: [
                CapLanguageBundleAdjuster(cap: 5034.0),
                LanguageBundleDosageMgOffsetAdjuster(weight: 1.7),
                RoundingLanguageBundleAdjuster(step: 5.0),
                NameLanguageBundleAdjuster(factors: ["west": 1.01, "online": 1.39, "east": 1.2]),
                MinimumLanguageBundleAdjuster(minimum: 11.3),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 42426.1
        )
    }
}
