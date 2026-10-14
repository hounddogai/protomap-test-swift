import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol policy calculation.
    protocol CareProtocolPolicyModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolPolicy, value: Double) -> Double
    }

    final class TieredCareProtocolPolicyAdjuster: CareProtocolPolicyModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CareProtocolPolicyVersionOffsetAdjuster: CareProtocolPolicyModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: CareProtocolPolicy, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class FlaggedCareProtocolPolicyAdjuster: CareProtocolPolicyModifier {
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

        func adjust(_ item: CareProtocolPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareProtocolPolicyAdjuster: CareProtocolPolicyModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCareProtocolPolicyAdjuster: CareProtocolPolicyModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCareProtocolPolicyAdjuster: CareProtocolPolicyModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care protocol policy steps in order and keeps a trace of each.
    final class CareProtocolPolicyEngine {
        var steps: [any CareProtocolPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareProtocolPolicy) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [CareProtocolPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareProtocolPolicyEngine(_ flags: Kit.Flags.Registry) -> CareProtocolPolicyEngine {
        return CareProtocolPolicyEngine(
            steps: [
                TieredCareProtocolPolicyAdjuster(bounds: [4371.0, 5167.0, 8821.0], rates: [0.82, 0.94, 1.19]),
                CareProtocolPolicyVersionOffsetAdjuster(weight: 0.06),
                FlaggedCareProtocolPolicyAdjuster(flags: flags, flag: "care-protocol-policy-pending", percent: -8.4),
                MinimumCareProtocolPolicyAdjuster(minimum: 30.3),
                CapCareProtocolPolicyAdjuster(cap: 45850.0),
                PercentCareProtocolPolicyAdjuster(percent: -24.9),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 72078.7
        )
    }
}
