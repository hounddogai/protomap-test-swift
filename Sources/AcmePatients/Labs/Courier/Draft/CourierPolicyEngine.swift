import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier policy calculation.
    protocol CourierPolicyModifier {
        func describe() -> String
        func adjust(_ item: CourierPolicy, value: Double) -> Double
    }

    final class PercentCourierPolicyAdjuster: CourierPolicyModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCourierPolicyAdjuster: CourierPolicyModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCourierPolicyAdjuster: CourierPolicyModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCourierPolicyAdjuster: CourierPolicyModifier {
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

        func adjust(_ item: CourierPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the courier policy steps in order and keeps a trace of each.
    final class CourierPolicyEngine {
        var steps: [any CourierPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CourierPolicy) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [CourierPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCourierPolicyEngine(_ flags: Kit.Flags.Registry) -> CourierPolicyEngine {
        return CourierPolicyEngine(
            steps: [
                PercentCourierPolicyAdjuster(percent: -3.4),
                CapCourierPolicyAdjuster(cap: 23710.0),
                TieredCourierPolicyAdjuster(bounds: [361.0, 3024.0, 8748.0], rates: [1.13, 1.11, 1.03]),
                FlaggedCourierPolicyAdjuster(flags: flags, flag: "courier-policy-manual", percent: 7.4),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 73454.3
        )
    }
}
