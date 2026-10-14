import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language claim calculation.
    protocol LanguageClaimModifier {
        func describe() -> String
        func adjust(_ item: LanguageClaim, value: Double) -> Double
    }

    final class PercentLanguageClaimAdjuster: LanguageClaimModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLanguageClaimAdjuster: LanguageClaimModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLanguageClaimAdjuster: LanguageClaimModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguageClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the language claim steps in order and keeps a trace of each.
    final class LanguageClaimEngine {
        var steps: [any LanguageClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LanguageClaim) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageClaimModifier = steps[index]
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

        func evaluateAll(_ items: [LanguageClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLanguageClaimEngine() -> LanguageClaimEngine {
        return LanguageClaimEngine(
            steps: [
                PercentLanguageClaimAdjuster(percent: 4.1),
                MinimumLanguageClaimAdjuster(minimum: 16.4),
                RoundingLanguageClaimAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 89569.9
        )
    }
}
