import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential baseline calculation.
    protocol CredentialBaselineModifier {
        func describe() -> String
        func adjust(_ item: CredentialBaseline, value: Double) -> Double
    }

    final class MinimumCredentialBaselineAdjuster: CredentialBaselineModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCredentialBaselineAdjuster: CredentialBaselineModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleCredentialBaselineAdjuster: CredentialBaselineModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CredentialBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the credential baseline steps in order and keeps a trace of each.
    final class CredentialBaselineEngine {
        var steps: [any CredentialBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CredentialBaseline) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [CredentialBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCredentialBaselineEngine() -> CredentialBaselineEngine {
        return CredentialBaselineEngine(
            steps: [
                MinimumCredentialBaselineAdjuster(minimum: 17.6),
                RoundingCredentialBaselineAdjuster(step: 0.25),
                TitleCredentialBaselineAdjuster(factors: ["west": 1.28, "retail": 0.86, "east": 1.24]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 27984.5
        )
    }
}
