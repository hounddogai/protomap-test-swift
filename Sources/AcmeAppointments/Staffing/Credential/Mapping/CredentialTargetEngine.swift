import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential target calculation.
    protocol CredentialTargetModifier {
        func describe() -> String
        func adjust(_ item: CredentialTarget, value: Double) -> Double
    }

    final class MinimumCredentialTargetAdjuster: CredentialTargetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCredentialTargetAdjuster: CredentialTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCredentialTargetAdjuster: CredentialTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the credential target steps in order and keeps a trace of each.
    final class CredentialTargetEngine {
        var steps: [any CredentialTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CredentialTarget) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [CredentialTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCredentialTargetEngine() -> CredentialTargetEngine {
        return CredentialTargetEngine(
            steps: [
                MinimumCredentialTargetAdjuster(minimum: 2.5),
                TieredCredentialTargetAdjuster(bounds: [525.0, 5171.0], rates: [1.11, 1.16]),
                CapCredentialTargetAdjuster(cap: 26430.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 60018.0
        )
    }
}
