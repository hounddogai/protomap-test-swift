import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential adjustment calculation.
    protocol CredentialAdjustmentFactor {
        func describe() -> String
        func adjust(_ item: CredentialAdjustment, value: Double) -> Double
    }

    final class CredentialAdjustmentMaximumOffsetAdjuster: CredentialAdjustmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: CredentialAdjustment, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class TieredCredentialAdjustmentAdjuster: CredentialAdjustmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCredentialAdjustmentAdjuster: CredentialAdjustmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCredentialAdjustmentAdjuster: CredentialAdjustmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FacilityCredentialAdjustmentAdjuster: CredentialAdjustmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: CredentialAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCredentialAdjustmentAdjuster: CredentialAdjustmentFactor {
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

        func adjust(_ item: CredentialAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the credential adjustment steps in order and keeps a trace of each.
    final class CredentialAdjustmentEngine {
        var steps: [any CredentialAdjustmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialAdjustmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CredentialAdjustment) -> Double {
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

        func evaluateAll(_ items: [CredentialAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCredentialAdjustmentEngine(_ flags: Kit.Flags.Registry) -> CredentialAdjustmentEngine {
        return CredentialAdjustmentEngine(
            steps: [
                CredentialAdjustmentMaximumOffsetAdjuster(weight: 0.01),
                TieredCredentialAdjustmentAdjuster(
                    bounds: [182.0, 1090.0, 7321.0, 8280.0],
                    rates: [0.8, 1.01, 0.87, 1.01]
                ),
                PercentCredentialAdjustmentAdjuster(percent: -18.2),
                CapCredentialAdjustmentAdjuster(cap: 48549.0),
                FacilityCredentialAdjustmentAdjuster(factors: ["west": 1.2, "central": 0.87, "east": 1.32]),
                FlaggedCredentialAdjustmentAdjuster(
                    flags: flags,
                    flag: "credential-adjustment-batched",
                    percent: -8.7
                ),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 85697.0
        )
    }
}
