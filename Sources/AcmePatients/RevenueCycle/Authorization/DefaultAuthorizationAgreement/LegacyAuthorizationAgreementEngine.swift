import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the legacy authorization agreement calculation.
    protocol LegacyAuthorizationAgreementModifier {
        func describe() -> String
        func adjust(_ item: LegacyAuthorizationAgreement, value: Double) -> Double
    }

    final class PercentLegacyAuthorizationAgreementAdjuster: LegacyAuthorizationAgreementModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyAuthorizationAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardLegacyAuthorizationAgreementAdjuster: LegacyAuthorizationAgreementModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: LegacyAuthorizationAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLegacyAuthorizationAgreementAdjuster: LegacyAuthorizationAgreementModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyAuthorizationAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLegacyAuthorizationAgreementAdjuster: LegacyAuthorizationAgreementModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyAuthorizationAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy authorization agreement steps in order and keeps a trace of each.
    final class LegacyAuthorizationAgreementEngine {
        var steps: [any LegacyAuthorizationAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAuthorizationAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyAuthorizationAgreement) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [LegacyAuthorizationAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyAuthorizationAgreementEngine() -> LegacyAuthorizationAgreementEngine {
        return LegacyAuthorizationAgreementEngine(
            steps: [
                PercentLegacyAuthorizationAgreementAdjuster(percent: 22.9),
                WardLegacyAuthorizationAgreementAdjuster(factors: ["east": 1.33, "north": 0.72, "retail": 1.37]),
                RoundingLegacyAuthorizationAgreementAdjuster(step: 1.0),
                CapLegacyAuthorizationAgreementAdjuster(cap: 28547.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 81165.6
        )
    }
}
