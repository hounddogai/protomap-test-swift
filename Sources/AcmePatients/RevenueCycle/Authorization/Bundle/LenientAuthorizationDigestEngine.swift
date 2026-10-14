import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient authorization digest calculation.
    protocol LenientAuthorizationDigestAdjuster {
        func describe() -> String
        func adjust(_ item: LenientAuthorizationDigest, value: Double) -> Double
    }

    final class PercentLenientAuthorizationDigestAdjuster: LenientAuthorizationDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientAuthorizationDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelLenientAuthorizationDigestAdjuster: LenientAuthorizationDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientAuthorizationDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LenientAuthorizationDigestExpiresAtOffsetAdjuster: LenientAuthorizationDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: LenientAuthorizationDigest, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class RoundingLenientAuthorizationDigestAdjuster: LenientAuthorizationDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientAuthorizationDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient authorization digest steps in order and keeps a trace of each.
    final class LenientAuthorizationDigestEngine {
        var steps: [any LenientAuthorizationDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientAuthorizationDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientAuthorizationDigest) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [LenientAuthorizationDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientAuthorizationDigestEngine() -> LenientAuthorizationDigestEngine {
        return LenientAuthorizationDigestEngine(
            steps: [
                PercentLenientAuthorizationDigestAdjuster(percent: 19.2),
                LabelLenientAuthorizationDigestAdjuster(factors: ["central": 1.12, "south": 1.09]),
                LenientAuthorizationDigestExpiresAtOffsetAdjuster(weight: 0.13),
                RoundingLenientAuthorizationDigestAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 16859.6
        )
    }
}
