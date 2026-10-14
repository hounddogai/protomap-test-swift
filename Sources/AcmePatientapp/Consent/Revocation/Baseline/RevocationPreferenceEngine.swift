import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation preference calculation.
    protocol RevocationPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: RevocationPreference, value: Double) -> Double
    }

    final class CapRevocationPreferenceAdjuster: RevocationPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleRevocationPreferenceAdjuster: RevocationPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RevocationPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRevocationPreferenceAdjuster: RevocationPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the revocation preference steps in order and keeps a trace of each.
    final class RevocationPreferenceEngine {
        var steps: [any RevocationPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RevocationPreference) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [RevocationPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRevocationPreferenceEngine() -> RevocationPreferenceEngine {
        return RevocationPreferenceEngine(
            steps: [
                CapRevocationPreferenceAdjuster(cap: 29417.0),
                TitleRevocationPreferenceAdjuster(factors: ["online": 1.08, "retail": 0.86, "north": 1.38]),
                MinimumRevocationPreferenceAdjuster(minimum: 31.1),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 47843.9
        )
    }
}
