import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim digest calculation.
    protocol ClaimDigestAdjuster {
        func describe() -> String
        func adjust(_ item: ClaimDigest, value: Double) -> Double
    }

    final class ClaimDigestDosageMgOffsetAdjuster: ClaimDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: ClaimDigest, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class MinimumClaimDigestAdjuster: ClaimDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapClaimDigestAdjuster: ClaimDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the claim digest steps in order and keeps a trace of each.
    final class ClaimDigestEngine {
        var steps: [any ClaimDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClaimDigest) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [ClaimDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClaimDigestEngine() -> ClaimDigestEngine {
        return ClaimDigestEngine(
            steps: [
                ClaimDigestDosageMgOffsetAdjuster(weight: 1.65),
                MinimumClaimDigestAdjuster(minimum: 39.9),
                CapClaimDigestAdjuster(cap: 1344.0),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 43348.3
        )
    }
}
