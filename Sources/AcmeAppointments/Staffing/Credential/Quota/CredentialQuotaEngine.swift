import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential quota calculation.
    protocol CredentialQuotaFactor {
        func describe() -> String
        func adjust(_ item: CredentialQuota, value: Double) -> Double
    }

    final class PercentCredentialQuotaAdjuster: CredentialQuotaFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CredentialQuotaMarginOffsetAdjuster: CredentialQuotaFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: CredentialQuota, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class RoundingCredentialQuotaAdjuster: CredentialQuotaFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCredentialQuotaAdjuster: CredentialQuotaFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityCredentialQuotaAdjuster: CredentialQuotaFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: CredentialQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the credential quota steps in order and keeps a trace of each.
    final class CredentialQuotaEngine {
        var steps: [any CredentialQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CredentialQuota) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [CredentialQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCredentialQuotaEngine() -> CredentialQuotaEngine {
        return CredentialQuotaEngine(
            steps: [
                PercentCredentialQuotaAdjuster(percent: -6.2),
                CredentialQuotaMarginOffsetAdjuster(weight: 0.02),
                RoundingCredentialQuotaAdjuster(step: 0.05),
                MinimumCredentialQuotaAdjuster(minimum: 22.5),
                FacilityCredentialQuotaAdjuster(factors: ["north": 1.03, "south": 1.35, "online": 0.78]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 58673.8
        )
    }
}
