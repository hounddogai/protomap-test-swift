import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered credential policy calculation.
    protocol TieredCredentialPolicyModifier {
        func describe() -> String
        func adjust(_ item: TieredCredentialPolicy, value: Double) -> Double
    }

    final class CapTieredCredentialPolicyAdjuster: TieredCredentialPolicyModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredCredentialPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTieredCredentialPolicyAdjuster: TieredCredentialPolicyModifier {
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

        func adjust(_ item: TieredCredentialPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredCredentialPolicyAdjuster: TieredCredentialPolicyModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredCredentialPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameTieredCredentialPolicyAdjuster: TieredCredentialPolicyModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TieredCredentialPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCredentialPolicyCapacityOffsetAdjuster: TieredCredentialPolicyModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: TieredCredentialPolicy, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class PercentTieredCredentialPolicyAdjuster: TieredCredentialPolicyModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredCredentialPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered credential policy steps in order and keeps a trace of each.
    final class TieredCredentialPolicyEngine {
        var steps: [any TieredCredentialPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredCredentialPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredCredentialPolicy) -> Double {
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

        func evaluateAll(_ items: [TieredCredentialPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredCredentialPolicyEngine(_ flags: Kit.Flags.Registry) -> TieredCredentialPolicyEngine {
        return TieredCredentialPolicyEngine(
            steps: [
                CapTieredCredentialPolicyAdjuster(cap: 864.0),
                FlaggedTieredCredentialPolicyAdjuster(
                    flags: flags,
                    flag: "tiered-credential-policy-regional",
                    percent: -6.8
                ),
                MinimumTieredCredentialPolicyAdjuster(minimum: 18.8),
                NameTieredCredentialPolicyAdjuster(factors: ["online": 0.91, "west": 0.87]),
                TieredCredentialPolicyCapacityOffsetAdjuster(weight: 1.09),
                PercentTieredCredentialPolicyAdjuster(percent: -8.6),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 79767.9
        )
    }
}
