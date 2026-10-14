import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation claim calculation.
    protocol RevocationClaimAdjuster {
        func describe() -> String
        func adjust(_ item: RevocationClaim, value: Double) -> Double
    }

    final class RevocationClaimAcuityOffsetAdjuster: RevocationClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: RevocationClaim, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class MinimumRevocationClaimAdjuster: RevocationClaimAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRevocationClaimAdjuster: RevocationClaimAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: RevocationClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleRevocationClaimAdjuster: RevocationClaimAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RevocationClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRevocationClaimAdjuster: RevocationClaimAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRevocationClaimAdjuster: RevocationClaimAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RevocationClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the revocation claim steps in order and keeps a trace of each.
    final class RevocationClaimEngine {
        var steps: [any RevocationClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RevocationClaim) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [RevocationClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRevocationClaimEngine(_ flags: Kit.Flags.Registry) -> RevocationClaimEngine {
        return RevocationClaimEngine(
            steps: [
                RevocationClaimAcuityOffsetAdjuster(weight: 1.16),
                MinimumRevocationClaimAdjuster(minimum: 49.8),
                FlaggedRevocationClaimAdjuster(flags: flags, flag: "revocation-claim-default", percent: 4.9),
                TitleRevocationClaimAdjuster(factors: ["east": 1.15, "west": 1.37, "north": 1.35]),
                PercentRevocationClaimAdjuster(percent: 18.8),
                TieredRevocationClaimAdjuster(bounds: [3088.0, 6528.0, 6818.0], rates: [1.01, 1.11, 0.99]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 55888.4
        )
    }
}
