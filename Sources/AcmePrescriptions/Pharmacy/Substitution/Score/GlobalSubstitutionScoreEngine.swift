import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the global substitution score calculation.
    protocol GlobalSubstitutionScoreFactor {
        func describe() -> String
        func adjust(_ item: GlobalSubstitutionScore, value: Double) -> Double
    }

    final class MinimumGlobalSubstitutionScoreAdjuster: GlobalSubstitutionScoreFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalSubstitutionScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapGlobalSubstitutionScoreAdjuster: GlobalSubstitutionScoreFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalSubstitutionScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleGlobalSubstitutionScoreAdjuster: GlobalSubstitutionScoreFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GlobalSubstitutionScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global substitution score steps in order and keeps a trace of each.
    final class GlobalSubstitutionScoreEngine {
        var steps: [any GlobalSubstitutionScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalSubstitutionScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalSubstitutionScore) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalSubstitutionScoreFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalSubstitutionScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalSubstitutionScoreEngine() -> GlobalSubstitutionScoreEngine {
        return GlobalSubstitutionScoreEngine(
            steps: [
                MinimumGlobalSubstitutionScoreAdjuster(minimum: 28.0),
                CapGlobalSubstitutionScoreAdjuster(cap: 24512.0),
                TitleGlobalSubstitutionScoreAdjuster(factors: ["online": 1.38, "east": 0.7]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 90354.5
        )
    }
}
