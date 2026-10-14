import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback consent form policy calculation.
    protocol FallbackConsentFormPolicyFactor {
        func describe() -> String
        func adjust(_ item: FallbackConsentFormPolicy, value: Double) -> Double
    }

    final class PercentFallbackConsentFormPolicyAdjuster: FallbackConsentFormPolicyFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackConsentFormPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackConsentFormPolicyAdjuster: FallbackConsentFormPolicyFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackConsentFormPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFallbackConsentFormPolicyAdjuster: FallbackConsentFormPolicyFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackConsentFormPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback consent form policy steps in order and keeps a trace of each.
    final class FallbackConsentFormPolicyEngine {
        var steps: [any FallbackConsentFormPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackConsentFormPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackConsentFormPolicy) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackConsentFormPolicyFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackConsentFormPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackConsentFormPolicyEngine() -> FallbackConsentFormPolicyEngine {
        return FallbackConsentFormPolicyEngine(
            steps: [
                PercentFallbackConsentFormPolicyAdjuster(percent: -16.5),
                RoundingFallbackConsentFormPolicyAdjuster(step: 0.25),
                CapFallbackConsentFormPolicyAdjuster(cap: 44162.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 6478.1
        )
    }
}
