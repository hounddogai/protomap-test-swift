import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim agreement calculation.
    protocol ClaimAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: ClaimAgreement, value: Double) -> Double
    }

    final class PercentClaimAgreementAdjuster: ClaimAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingClaimAgreementAdjuster: ClaimAgreementAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameClaimAgreementAdjuster: ClaimAgreementAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ClaimAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ClaimAgreementBatchSizeOffsetAdjuster: ClaimAgreementAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ClaimAgreement, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class CapClaimAgreementAdjuster: ClaimAgreementAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumClaimAgreementAdjuster: ClaimAgreementAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the claim agreement steps in order and keeps a trace of each.
    final class ClaimAgreementEngine {
        var steps: [any ClaimAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClaimAgreement) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [ClaimAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClaimAgreementEngine() -> ClaimAgreementEngine {
        return ClaimAgreementEngine(
            steps: [
                PercentClaimAgreementAdjuster(percent: 5.6),
                RoundingClaimAgreementAdjuster(step: 1.0),
                NameClaimAgreementAdjuster(factors: ["online": 1.15, "north": 0.96]),
                ClaimAgreementBatchSizeOffsetAdjuster(weight: 1.46),
                CapClaimAgreementAdjuster(cap: 1502.0),
                MinimumClaimAgreementAdjuster(minimum: 46.3),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 80539.9
        )
    }
}
