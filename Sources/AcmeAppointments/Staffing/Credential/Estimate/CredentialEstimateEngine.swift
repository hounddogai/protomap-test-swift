import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential estimate calculation.
    protocol CredentialEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: CredentialEstimate, value: Double) -> Double
    }

    final class TieredCredentialEstimateAdjuster: CredentialEstimateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCredentialEstimateAdjuster: CredentialEstimateAdjuster {
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

        func adjust(_ item: CredentialEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCredentialEstimateAdjuster: CredentialEstimateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCredentialEstimateAdjuster: CredentialEstimateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCredentialEstimateAdjuster: CredentialEstimateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the credential estimate steps in order and keeps a trace of each.
    final class CredentialEstimateEngine {
        var steps: [any CredentialEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CredentialEstimate) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CredentialEstimateAdjuster = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [CredentialEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCredentialEstimateEngine(_ flags: Kit.Flags.Registry) -> CredentialEstimateEngine {
        return CredentialEstimateEngine(
            steps: [
                TieredCredentialEstimateAdjuster(bounds: [1528.0, 3701.0, 4785.0], rates: [1.07, 1.13, 1.04]),
                FlaggedCredentialEstimateAdjuster(flags: flags, flag: "credential-estimate-strict", percent: 4.4),
                CapCredentialEstimateAdjuster(cap: 14462.0),
                PercentCredentialEstimateAdjuster(percent: 3.9),
                MinimumCredentialEstimateAdjuster(minimum: 13.7),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 77794.3
        )
    }
}
