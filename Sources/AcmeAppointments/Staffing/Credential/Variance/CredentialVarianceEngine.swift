import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential variance calculation.
    protocol CredentialVarianceModifier {
        func describe() -> String
        func adjust(_ item: CredentialVariance, value: Double) -> Double
    }

    final class MinimumCredentialVarianceAdjuster: CredentialVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentCredentialVarianceAdjuster: CredentialVarianceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCredentialVarianceAdjuster: CredentialVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CredentialVarianceCopayOffsetAdjuster: CredentialVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: CredentialVariance, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    /// Runs the credential variance steps in order and keeps a trace of each.
    final class CredentialVarianceEngine {
        var steps: [any CredentialVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CredentialVariance) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [CredentialVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCredentialVarianceEngine() -> CredentialVarianceEngine {
        return CredentialVarianceEngine(
            steps: [
                MinimumCredentialVarianceAdjuster(minimum: 32.3),
                PercentCredentialVarianceAdjuster(percent: -23.0),
                CapCredentialVarianceAdjuster(cap: 29024.0),
                CredentialVarianceCopayOffsetAdjuster(weight: 0.72),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 87329.3
        )
    }
}
